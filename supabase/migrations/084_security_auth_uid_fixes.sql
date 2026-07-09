-- 084_security_auth_uid_fixes.sql
--
-- Tetter tre sikkerhetshull i de sosiale funksjonene.
--
-- 1. get_feed(p_user_id, …)
--    SECURITY DEFINER-funksjon som tok bruker-ID som parameter fra klienten og
--    aldri kalte auth.uid(). Enhver innlogget bruker kunne sende inn en fremmed
--    UUID og lese den personens feed — RLS på posts ble omgått fullstendig.
--    Fiks: parameteren fjernes, auth.uid() brukes internt.
--
-- 2. toggle_post_like(p_post_id, p_user_id)
--    Samme feil: SECURITY DEFINER med klientstyrt p_user_id. Lot hvem som helst
--    like og AVLIKE på vegne av andre brukere.
--    Fiks: parameteren fjernes, auth.uid() brukes internt.
--
-- 3. friendships_update_recipient
--    Policyen hadde USING men ingen WITH CHECK. USING sjekker raden FØR
--    oppdateringen, WITH CHECK sjekker den ETTER. Uten den siste kunne mottakeren
--    skrive om requester_id til et vilkårlig offer og sette status='accepted' —
--    et forfalsket vennskap som låser opp offerets private profil, humidor og
--    innlegg.
--    Fiks: WITH CHECK som fryser begge parter og kun tillater status-overganger
--    fra 'pending'.
--
-- VIKTIG OM UTRULLING:
-- Build 169–178 ligger ute hos testere og kaller de gamle signaturene. Dropper vi
-- dem, slutter feeden å virke for alle som ikke har oppdatert. Derfor beholdes de
-- gamle signaturene som tynne shims som IGNORERER p_user_id og videresender til
-- de sikre funksjonene. Hullet er dermed tettet umiddelbart, også for gamle
-- klienter. Shimsene kan fjernes når 179+ er utbredt.

-- ── 1. get_feed uten p_user_id ──────────────────────────────────────────────

CREATE OR REPLACE FUNCTION public.get_feed(p_limit INT DEFAULT 50, p_offset INT DEFAULT 0)
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
            WHERE pl.post_id = p.id AND pl.user_id = auth.uid()
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
        auth.uid() IS NOT NULL
        AND (
            p.user_id = auth.uid()
            OR EXISTS (
                SELECT 1 FROM friendships f
                WHERE f.status = 'accepted'
                  AND (
                    (f.requester_id = auth.uid() AND f.recipient_id = p.user_id)
                    OR (f.recipient_id = auth.uid() AND f.requester_id = p.user_id)
                  )
            )
        )
        AND NOT EXISTS (
            SELECT 1 FROM user_blocks b
            WHERE (b.blocker_id = auth.uid() AND b.blocked_id = p.user_id)
               OR (b.blocker_id = p.user_id AND b.blocked_id = auth.uid())
        )
    ORDER BY p.created_at DESC
    LIMIT p_limit
    OFFSET p_offset;
$$;

GRANT EXECUTE ON FUNCTION public.get_feed(INT, INT) TO authenticated;

-- Shim for build ≤178: p_user_id ignoreres fullstendig.
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
LANGUAGE sql STABLE SECURITY INVOKER
SET search_path = public
AS $$
    SELECT * FROM public.get_feed(p_limit, p_offset);
$$;

GRANT EXECUTE ON FUNCTION public.get_feed(UUID, INT, INT) TO authenticated;

-- ── 2. toggle_post_like uten p_user_id ──────────────────────────────────────

CREATE OR REPLACE FUNCTION public.toggle_post_like(p_post_id UUID)
RETURNS BOOLEAN
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_uid    UUID := auth.uid();
    v_exists BOOLEAN;
BEGIN
    IF v_uid IS NULL THEN
        RAISE EXCEPTION 'Ikke innlogget';
    END IF;

    SELECT EXISTS (
        SELECT 1 FROM post_likes
        WHERE post_id = p_post_id AND user_id = v_uid
    ) INTO v_exists;

    IF v_exists THEN
        DELETE FROM post_likes WHERE post_id = p_post_id AND user_id = v_uid;
        RETURN FALSE;
    ELSE
        INSERT INTO post_likes (post_id, user_id) VALUES (p_post_id, v_uid);
        RETURN TRUE;
    END IF;
END;
$$;

GRANT EXECUTE ON FUNCTION public.toggle_post_like(UUID) TO authenticated;

-- Shim for build ≤178: p_user_id ignoreres fullstendig.
CREATE OR REPLACE FUNCTION public.toggle_post_like(p_post_id UUID, p_user_id UUID)
RETURNS BOOLEAN
LANGUAGE sql SECURITY INVOKER
SET search_path = public
AS $$
    SELECT public.toggle_post_like(p_post_id);
$$;

GRANT EXECUTE ON FUNCTION public.toggle_post_like(UUID, UUID) TO authenticated;

-- ── 3. friendships: forfalskede vennskap ────────────────────────────────────
--
-- To hull, ikke ett:
--
-- (a) Insert-policyen sjekket kun `auth.uid() = requester_id`. Ingenting hindret
--     en bruker i å sette inn en rad med status='accepted' direkte — altså et
--     ferdig vennskap med et vilkårlig offer, uten at offeret ble spurt.
--
-- (b) Update-policyen hadde USING men ingen WITH CHECK. Mottakeren kunne skrive
--     om requester_id til et offer og sette status='accepted'.
--
-- WITH CHECK alene løser ikke (b): den ser bare den NYE raden, og en angriper
-- som beholder seg selv som recipient_id består sjekken selv om requester_id er
-- byttet ut. Partene må derfor fryses med en trigger, som er det eneste stedet
-- man har tilgang til både OLD og NEW.

-- (a) Nye forespørsler må starte som 'pending', og man kan ikke bli venn med seg selv.
DROP POLICY IF EXISTS "friendships_insert_own" ON friendships;

CREATE POLICY "friendships_insert_own"
  ON friendships FOR INSERT
  WITH CHECK (
    auth.uid() = requester_id
    AND status = 'pending'
    AND recipient_id <> auth.uid()
  );

-- (b) Mottakeren kan kun flytte en 'pending' til 'accepted' eller 'declined'.
DROP POLICY IF EXISTS "friendships_update_recipient" ON friendships;

CREATE POLICY "friendships_update_recipient"
  ON friendships FOR UPDATE
  USING (auth.uid() = recipient_id AND status = 'pending')
  WITH CHECK (
    auth.uid() = recipient_id
    AND status IN ('accepted', 'declined')
  );

-- Partene fryses. En trigger er nødvendig fordi WITH CHECK ikke ser OLD-raden.
CREATE OR REPLACE FUNCTION public.friendships_freeze_parties()
RETURNS TRIGGER
LANGUAGE plpgsql
SET search_path = public
AS $$
BEGIN
    IF NEW.requester_id IS DISTINCT FROM OLD.requester_id
       OR NEW.recipient_id IS DISTINCT FROM OLD.recipient_id THEN
        RAISE EXCEPTION 'Partene i et vennskap kan ikke endres';
    END IF;
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS friendships_freeze_parties_trg ON friendships;

CREATE TRIGGER friendships_freeze_parties_trg
  BEFORE UPDATE ON friendships
  FOR EACH ROW EXECUTE FUNCTION public.friendships_freeze_parties();
