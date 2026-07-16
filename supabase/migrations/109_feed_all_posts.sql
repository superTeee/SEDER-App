-- Migrasjon 109: feeden viser ALLE innlegg, ikke bare venners
--
-- Tidligere returnerte get_feed kun egne + venners innlegg. Nå skal feeden være
-- åpen for alle (som en offentlig strøm), men fortsatt uten innlegg fra/til
-- brukere man har blokkert. Krever fortsatt innlogging (auth.uid()).

CREATE OR REPLACE FUNCTION public.get_feed(p_limit integer DEFAULT 50, p_offset integer DEFAULT 0)
RETURNS TABLE(id uuid, user_id uuid, author_name text, author_avatar_url text, content text, image_url text, created_at timestamp with time zone, like_count bigint, comment_count bigint, liked_by_me boolean, tasting_log_id uuid, cigar_brand text, cigar_series text, cigar_vitola text, cigar_rating integer, cigar_score_label text, tasting_photo_url text)
LANGUAGE sql
STABLE SECURITY DEFINER
SET search_path TO 'public'
AS $function$
    SELECT
        p.id, p.user_id,
        COALESCE(pr.display_name, 'Sigar-entusiast') AS author_name,
        pr.avatar_url AS author_avatar_url,
        p.content, p.image_url, p.created_at,
        (SELECT COUNT(*) FROM post_likes pl WHERE pl.post_id = p.id) AS like_count,
        (SELECT COUNT(*) FROM post_comments pc WHERE pc.post_id = p.id) AS comment_count,
        EXISTS (SELECT 1 FROM post_likes pl WHERE pl.post_id = p.id AND pl.user_id = auth.uid()) AS liked_by_me,
        tl.id AS tasting_log_id,
        c.brand AS cigar_brand, c.series AS cigar_series, c.vitola AS cigar_vitola,
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
    WHERE auth.uid() IS NOT NULL
      AND NOT EXISTS (
        SELECT 1 FROM user_blocks b
        WHERE (b.blocker_id = auth.uid() AND b.blocked_id = p.user_id)
           OR (b.blocker_id = p.user_id AND b.blocked_id = auth.uid())
      )
    ORDER BY p.created_at DESC
    LIMIT p_limit OFFSET p_offset;
$function$;
