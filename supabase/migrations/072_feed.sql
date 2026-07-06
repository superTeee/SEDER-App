-- ============================================================
-- Migration 072: Social Feed
-- Tabeller: posts, post_likes, post_comments
-- RPCs:     get_feed, toggle_post_like, get_post_comments
-- Storage:  post-images bucket
-- ============================================================

-- ── 1. POSTS ────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS public.posts (
    id              UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id         UUID        NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    tasting_log_id  UUID        REFERENCES public.tasting_logs(id) ON DELETE SET NULL,
    content         TEXT,
    image_url       TEXT,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Rask henting av feed (nyest fra venner og seg selv)
CREATE INDEX IF NOT EXISTS idx_posts_user_id     ON public.posts(user_id);
CREATE INDEX IF NOT EXISTS idx_posts_created_at  ON public.posts(created_at DESC);

ALTER TABLE public.posts ENABLE ROW LEVEL SECURITY;

-- Innloggede brukere kan lese poster fra seg selv og sine venner
CREATE POLICY "posts_select" ON public.posts
    FOR SELECT USING (
        auth.uid() IS NOT NULL
        AND (
            user_id = auth.uid()
            OR EXISTS (
                SELECT 1 FROM public.friendships f
                WHERE f.status = 'accepted'
                  AND (
                    (f.requester_id = auth.uid() AND f.recipient_id = posts.user_id)
                    OR (f.recipient_id = auth.uid() AND f.requester_id = posts.user_id)
                  )
            )
        )
    );

-- Brukere kan opprette egne poster
CREATE POLICY "posts_insert" ON public.posts
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Brukere kan slette egne poster
CREATE POLICY "posts_delete" ON public.posts
    FOR DELETE USING (auth.uid() = user_id);

-- ── 2. POST_LIKES ────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS public.post_likes (
    id          UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    post_id     UUID        NOT NULL REFERENCES public.posts(id) ON DELETE CASCADE,
    user_id     UUID        NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(post_id, user_id)
);

CREATE INDEX IF NOT EXISTS idx_post_likes_post_id ON public.post_likes(post_id);

ALTER TABLE public.post_likes ENABLE ROW LEVEL SECURITY;

CREATE POLICY "post_likes_select" ON public.post_likes
    FOR SELECT USING (auth.uid() IS NOT NULL);

CREATE POLICY "post_likes_insert" ON public.post_likes
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "post_likes_delete" ON public.post_likes
    FOR DELETE USING (auth.uid() = user_id);

-- ── 3. POST_COMMENTS ────────────────────────────────────────

CREATE TABLE IF NOT EXISTS public.post_comments (
    id          UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    post_id     UUID        NOT NULL REFERENCES public.posts(id) ON DELETE CASCADE,
    user_id     UUID        NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    content     TEXT        NOT NULL CHECK (char_length(content) BETWEEN 1 AND 1000),
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_post_comments_post_id ON public.post_comments(post_id);

ALTER TABLE public.post_comments ENABLE ROW LEVEL SECURITY;

CREATE POLICY "post_comments_select" ON public.post_comments
    FOR SELECT USING (auth.uid() IS NOT NULL);

CREATE POLICY "post_comments_insert" ON public.post_comments
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "post_comments_delete" ON public.post_comments
    FOR DELETE USING (auth.uid() = user_id);

-- ── 4. STORAGE: post-images ─────────────────────────────────

INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
    'post-images',
    'post-images',
    true,
    5242880,  -- 5 MB
    ARRAY['image/jpeg','image/png','image/webp','image/heic']
)
ON CONFLICT (id) DO NOTHING;

-- Storage RLS: kun eier kan laste opp/slette (path: {user_id}/{post_id}.jpg)
CREATE POLICY "post_images_select" ON storage.objects
    FOR SELECT USING (bucket_id = 'post-images');

CREATE POLICY "post_images_insert" ON storage.objects
    FOR INSERT WITH CHECK (
        bucket_id = 'post-images'
        AND auth.uid()::text = (storage.foldername(name))[1]
    );

CREATE POLICY "post_images_delete" ON storage.objects
    FOR DELETE USING (
        bucket_id = 'post-images'
        AND auth.uid()::text = (storage.foldername(name))[1]
    );

-- ── 5. RPC: get_feed ────────────────────────────────────────
-- Returnerer poster fra brukeren selv + aksepterte venner.
-- Inkluderer: forfatternavn, sigar-info fra tasting_log, like-count, kommentar-count, liked_by_me.

CREATE OR REPLACE FUNCTION public.get_feed(p_user_id UUID, p_limit INT DEFAULT 50, p_offset INT DEFAULT 0)
RETURNS TABLE (
    id              UUID,
    user_id         UUID,
    author_name     TEXT,
    content         TEXT,
    image_url       TEXT,
    created_at      TIMESTAMPTZ,
    like_count      BIGINT,
    comment_count   BIGINT,
    liked_by_me     BOOLEAN,
    -- Tasting log data (kan være NULL)
    tasting_log_id  UUID,
    cigar_brand     TEXT,
    cigar_series    TEXT,
    cigar_vitola    TEXT,
    cigar_rating    INT,
    cigar_score_label TEXT,
    tasting_photo_url TEXT
)
LANGUAGE sql STABLE SECURITY DEFINER
SET search_path = public
AS $$
    SELECT
        p.id,
        p.user_id,
        COALESCE(pr.display_name, 'Sigar-entusiast') AS author_name,
        p.content,
        p.image_url,
        p.created_at,

        -- Likes
        (SELECT COUNT(*) FROM post_likes pl WHERE pl.post_id = p.id)           AS like_count,
        -- Kommentarer
        (SELECT COUNT(*) FROM post_comments pc WHERE pc.post_id = p.id)         AS comment_count,
        -- Likt av meg?
        EXISTS (
            SELECT 1 FROM post_likes pl
            WHERE pl.post_id = p.id AND pl.user_id = p_user_id
        ) AS liked_by_me,

        -- Tasting log-kobling
        tl.id AS tasting_log_id,
        c.brand AS cigar_brand,
        c.series AS cigar_series,
        c.vitola AS cigar_vitola,
        tl.rating AS cigar_rating,
        CASE
            WHEN tl.rating >= 95 THEN 'Eksepsjonell'
            WHEN tl.rating >= 90 THEN 'Fremragende'
            WHEN tl.rating >= 85 THEN 'Meget bra'
            WHEN tl.rating >= 80 THEN 'Bra'
            WHEN tl.rating >= 70 THEN 'Grei'
            WHEN tl.rating IS NOT NULL THEN 'Ikke for meg'
            ELSE NULL
        END AS cigar_score_label,
        tl.photo_url AS tasting_photo_url

    FROM posts p
    LEFT JOIN profiles pr ON pr.id = p.user_id
    LEFT JOIN tasting_logs tl ON tl.id = p.tasting_log_id
    LEFT JOIN cigars c ON c.id = tl.cigar_id

    WHERE
        p.user_id = p_user_id
        OR EXISTS (
            SELECT 1 FROM friendships f
            WHERE f.status = 'accepted'
              AND (
                (f.requester_id = p_user_id AND f.recipient_id = p.user_id)
                OR (f.recipient_id = p_user_id AND f.requester_id = p.user_id)
              )
        )

    ORDER BY p.created_at DESC
    LIMIT p_limit
    OFFSET p_offset;
$$;

GRANT EXECUTE ON FUNCTION public.get_feed(UUID, INT, INT) TO authenticated;

-- ── 6. RPC: toggle_post_like ────────────────────────────────
-- Legger til eller fjerner en like. Returnerer ny liked_by_me-status.

CREATE OR REPLACE FUNCTION public.toggle_post_like(p_post_id UUID, p_user_id UUID)
RETURNS BOOLEAN
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_exists BOOLEAN;
BEGIN
    SELECT EXISTS (
        SELECT 1 FROM post_likes
        WHERE post_id = p_post_id AND user_id = p_user_id
    ) INTO v_exists;

    IF v_exists THEN
        DELETE FROM post_likes WHERE post_id = p_post_id AND user_id = p_user_id;
        RETURN FALSE;
    ELSE
        INSERT INTO post_likes (post_id, user_id) VALUES (p_post_id, p_user_id);
        RETURN TRUE;
    END IF;
END;
$$;

GRANT EXECUTE ON FUNCTION public.toggle_post_like(UUID, UUID) TO authenticated;

-- ── 7. RPC: get_post_comments ────────────────────────────────
-- Henter kommentarer til et innlegg med forfatternavn.

CREATE OR REPLACE FUNCTION public.get_post_comments(p_post_id UUID)
RETURNS TABLE (
    id          UUID,
    post_id     UUID,
    user_id     UUID,
    author_name TEXT,
    content     TEXT,
    created_at  TIMESTAMPTZ
)
LANGUAGE sql STABLE SECURITY DEFINER
SET search_path = public
AS $$
    SELECT
        pc.id,
        pc.post_id,
        pc.user_id,
        COALESCE(pr.display_name, 'Sigar-entusiast') AS author_name,
        pc.content,
        pc.created_at
    FROM post_comments pc
    LEFT JOIN profiles pr ON pr.id = pc.user_id
    WHERE pc.post_id = p_post_id
    ORDER BY pc.created_at ASC;
$$;

GRANT EXECUTE ON FUNCTION public.get_post_comments(UUID) TO authenticated;
