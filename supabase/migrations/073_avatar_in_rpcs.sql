-- Migration 073: Legg til avatar_url i alle sosiale RPC-er
-- Oppdaterer get_feed, get_post_comments, get_friends_and_requests og search_users
-- slik at profilbilder kan vises i feed, venneliste og søkeresultater.

-- ── 1. get_feed — legg til author_avatar_url ─────────────────

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

-- ── 2. get_post_comments — legg til author_avatar_url ────────

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
    ORDER BY pc.created_at ASC;
$$;

GRANT EXECUTE ON FUNCTION public.get_post_comments(UUID) TO authenticated;

-- ── 3. get_friends_and_requests — legg til other_avatar_url ──

CREATE OR REPLACE FUNCTION public.get_friends_and_requests()
RETURNS TABLE (
    friendship_id       UUID,
    other_user_id       UUID,
    other_display_name  TEXT,
    other_avatar_url    TEXT,
    status              TEXT,
    direction           TEXT,
    created_at          TIMESTAMPTZ
)
SECURITY DEFINER
SET search_path = public
LANGUAGE sql
AS $$
    SELECT
        f.id,
        CASE WHEN f.requester_id = auth.uid() THEN f.recipient_id ELSE f.requester_id END,
        p.display_name,
        p.avatar_url,
        f.status,
        CASE WHEN f.requester_id = auth.uid() THEN 'outgoing' ELSE 'incoming' END,
        f.created_at
    FROM friendships f
    JOIN profiles p
        ON p.id = CASE WHEN f.requester_id = auth.uid() THEN f.recipient_id ELSE f.requester_id END
    WHERE f.requester_id = auth.uid() OR f.recipient_id = auth.uid()
    ORDER BY f.created_at DESC;
$$;

GRANT EXECUTE ON FUNCTION public.get_friends_and_requests() TO authenticated;

-- ── 4. search_users — legg til avatar_url ────────────────────

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
    ORDER BY p.display_name
    LIMIT 20;
$$;

GRANT EXECUTE ON FUNCTION public.search_users(text) TO authenticated;
