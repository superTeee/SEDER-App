-- ============================================================
-- Migration 075: Rapportering av innlegg + blokkering av brukere
-- (App Store-krav 1.2 for apper med brukergenerert innhold)
--
-- Tabeller: post_reports, user_blocks
-- RPC-er:   report_post, block_user, unblock_user
-- Oppdaterer: get_feed, get_post_comments, search_users
--             til å skjule innhold fra/til blokkerte brukere.
-- ============================================================

-- ── 1. POST_REPORTS ─────────────────────────────────────────

CREATE TABLE IF NOT EXISTS public.post_reports (
    id           UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    post_id      UUID        NOT NULL REFERENCES public.posts(id) ON DELETE CASCADE,
    reporter_id  UUID        NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    reason       TEXT        NOT NULL,
    status       TEXT        NOT NULL DEFAULT 'pending',
    created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(post_id, reporter_id)
);

CREATE INDEX IF NOT EXISTS idx_post_reports_post_id ON public.post_reports(post_id);
CREATE INDEX IF NOT EXISTS idx_post_reports_status  ON public.post_reports(status);

ALTER TABLE public.post_reports ENABLE ROW LEVEL SECURITY;

-- Brukere kan opprette egne rapporter og se sine egne
CREATE POLICY "post_reports_insert" ON public.post_reports
    FOR INSERT WITH CHECK (auth.uid() = reporter_id);
CREATE POLICY "post_reports_select_own" ON public.post_reports
    FOR SELECT USING (auth.uid() = reporter_id);

-- ── 2. USER_BLOCKS ──────────────────────────────────────────

CREATE TABLE IF NOT EXISTS public.user_blocks (
    id          UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    blocker_id  UUID        NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    blocked_id  UUID        NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(blocker_id, blocked_id),
    CHECK (blocker_id <> blocked_id)
);

CREATE INDEX IF NOT EXISTS idx_user_blocks_blocker ON public.user_blocks(blocker_id);
CREATE INDEX IF NOT EXISTS idx_user_blocks_blocked ON public.user_blocks(blocked_id);

ALTER TABLE public.user_blocks ENABLE ROW LEVEL SECURITY;

CREATE POLICY "user_blocks_select_own" ON public.user_blocks
    FOR SELECT USING (auth.uid() = blocker_id);
CREATE POLICY "user_blocks_insert" ON public.user_blocks
    FOR INSERT WITH CHECK (auth.uid() = blocker_id);
CREATE POLICY "user_blocks_delete" ON public.user_blocks
    FOR DELETE USING (auth.uid() = blocker_id);

-- ── 3. RPC: report_post ─────────────────────────────────────

CREATE OR REPLACE FUNCTION public.report_post(p_post_id UUID, p_reason TEXT)
RETURNS VOID
LANGUAGE sql SECURITY DEFINER
SET search_path = public
AS $$
    INSERT INTO post_reports (post_id, reporter_id, reason)
    VALUES (p_post_id, auth.uid(), p_reason)
    ON CONFLICT (post_id, reporter_id)
        DO UPDATE SET reason = EXCLUDED.reason, created_at = NOW(), status = 'pending';
$$;

GRANT EXECUTE ON FUNCTION public.report_post(UUID, TEXT) TO authenticated;

-- ── 4. RPC: block_user (blokkerer + fjerner evt. vennskap) ───

CREATE OR REPLACE FUNCTION public.block_user(p_blocked_id UUID)
RETURNS VOID
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    IF p_blocked_id = auth.uid() OR p_blocked_id IS NULL THEN
        RETURN;
    END IF;

    INSERT INTO user_blocks (blocker_id, blocked_id)
    VALUES (auth.uid(), p_blocked_id)
    ON CONFLICT (blocker_id, blocked_id) DO NOTHING;

    -- Fjern eventuelt vennskap mellom de to
    DELETE FROM friendships f
    WHERE (f.requester_id = auth.uid() AND f.recipient_id = p_blocked_id)
       OR (f.recipient_id = auth.uid() AND f.requester_id = p_blocked_id);
END;
$$;

GRANT EXECUTE ON FUNCTION public.block_user(UUID) TO authenticated;

-- ── 5. RPC: unblock_user ────────────────────────────────────

CREATE OR REPLACE FUNCTION public.unblock_user(p_blocked_id UUID)
RETURNS VOID
LANGUAGE sql SECURITY DEFINER
SET search_path = public
AS $$
    DELETE FROM user_blocks
    WHERE blocker_id = auth.uid() AND blocked_id = p_blocked_id;
$$;

GRANT EXECUTE ON FUNCTION public.unblock_user(UUID) TO authenticated;

-- ── 6. get_feed — skjul blokkerte brukere (begge retninger) ──

CREATE OR REPLACE FUNCTION public.get_feed(p_user_id UUID, p_limit INT DEFAULT 50, p_offset INT DEFAULT 0)
RETURNS TABLE (
    id                  UUID,
    user_id             UUID,
    author_name         TEXT,
    author_avatar_url   TEXT,
    content             TEXT,
    image_url           TEXT,
    created_at          TIMESTAMPTZ,
    like_count          BIGINT,
    comment_count       BIGINT,
    liked_by_me         BOOLEAN,
    tasting_log_id      UUID,
    cigar_brand         TEXT,
    cigar_series        TEXT,
    cigar_vitola        TEXT,
    cigar_rating        INT,
    cigar_score_label   TEXT,
    tasting_photo_url   TEXT
)
LANGUAGE sql STABLE SECURITY DEFINER
SET search_path = public
AS $$
    SELECT
        p.id,
        p.user_id,
        COALESCE(pr.display_name, 'Sigar-entusiast') AS author_name,
        pr.avatar_url                                 AS author_avatar_url,
        p.content,
        p.image_url,
        p.created_at,
        (SELECT COUNT(*) FROM post_likes pl WHERE pl.post_id = p.id)    AS like_count,
        (SELECT COUNT(*) FROM post_comments pc WHERE pc.post_id = p.id) AS comment_count,
        EXISTS (
            SELECT 1 FROM post_likes pl
            WHERE pl.post_id = p.id AND pl.user_id = p_user_id
        ) AS liked_by_me,
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
        (
            p.user_id = p_user_id
            OR EXISTS (
                SELECT 1 FROM friendships f
                WHERE f.status = 'accepted'
                  AND (
                    (f.requester_id = p_user_id AND f.recipient_id = p.user_id)
                    OR (f.recipient_id = p_user_id AND f.requester_id = p.user_id)
                  )
            )
        )
        AND NOT EXISTS (
            SELECT 1 FROM user_blocks b
            WHERE (b.blocker_id = p_user_id AND b.blocked_id = p.user_id)
               OR (b.blocker_id = p.user_id AND b.blocked_id = p_user_id)
        )
    ORDER BY p.created_at DESC
    LIMIT p_limit
    OFFSET p_offset;
$$;

GRANT EXECUTE ON FUNCTION public.get_feed(UUID, INT, INT) TO authenticated;

-- ── 7. get_post_comments — skjul kommentarer fra blokkerte ───

CREATE OR REPLACE FUNCTION public.get_post_comments(p_post_id UUID)
RETURNS TABLE (
    id                  UUID,
    post_id             UUID,
    user_id             UUID,
    author_name         TEXT,
    author_avatar_url   TEXT,
    content             TEXT,
    created_at          TIMESTAMPTZ
)
LANGUAGE sql STABLE SECURITY DEFINER
SET search_path = public
AS $$
    SELECT
        pc.id,
        pc.post_id,
        pc.user_id,
        COALESCE(pr.display_name, 'Sigar-entusiast') AS author_name,
        pr.avatar_url                                 AS author_avatar_url,
        pc.content,
        pc.created_at
    FROM post_comments pc
    LEFT JOIN profiles pr ON pr.id = pc.user_id
    WHERE pc.post_id = p_post_id
      AND NOT EXISTS (
          SELECT 1 FROM user_blocks b
          WHERE (b.blocker_id = auth.uid() AND b.blocked_id = pc.user_id)
             OR (b.blocker_id = pc.user_id AND b.blocked_id = auth.uid())
      )
    ORDER BY pc.created_at ASC;
$$;

GRANT EXECUTE ON FUNCTION public.get_post_comments(UUID) TO authenticated;

-- ── 8. search_users — skjul blokkerte brukere ───────────────

CREATE OR REPLACE FUNCTION public.search_users(p_query text)
RETURNS TABLE (id UUID, display_name TEXT, friend_code TEXT, avatar_url TEXT)
SECURITY DEFINER
SET search_path = public
LANGUAGE sql
AS $$
    SELECT
        p.id,
        p.display_name,
        p.friend_code,
        p.avatar_url
    FROM profiles p
    WHERE p.id != auth.uid()
      AND trim(p_query) != ''
      AND (
        p.display_name ILIKE '%' || trim(p_query) || '%'
        OR p.friend_code = upper(trim(p_query))
      )
      AND NOT EXISTS (
          SELECT 1 FROM user_blocks b
          WHERE (b.blocker_id = auth.uid() AND b.blocked_id = p.id)
             OR (b.blocker_id = p.id AND b.blocked_id = auth.uid())
      )
    ORDER BY p.display_name
    LIMIT 20;
$$;

GRANT EXECUTE ON FUNCTION public.search_users(text) TO authenticated;
