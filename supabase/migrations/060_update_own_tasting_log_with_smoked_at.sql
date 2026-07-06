-- Migration 060: Recreate update_own_tasting_log to ensure smoked_at is updated
-- The original function (created ad-hoc) may not include smoked_at in the UPDATE.
-- This replaces it with a correct version covering all editable fields.

CREATE OR REPLACE FUNCTION update_own_tasting_log(
    p_id            UUID,
    p_smoked_at     TIMESTAMPTZ,
    p_rating        INT         DEFAULT NULL,
    p_smoke_again   BOOLEAN     DEFAULT NULL,
    p_draw_rating   INT         DEFAULT NULL,
    p_burn_rating   INT         DEFAULT NULL,
    p_flavor_rating INT         DEFAULT NULL,
    p_personal_notes TEXT       DEFAULT NULL,
    p_photo_url     TEXT        DEFAULT NULL
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    UPDATE tasting_logs
    SET
        smoked_at      = p_smoked_at,
        rating         = p_rating,
        smoke_again    = p_smoke_again,
        draw_rating    = p_draw_rating,
        burn_rating    = p_burn_rating,
        flavor_rating  = p_flavor_rating,
        personal_notes = p_personal_notes,
        photo_url      = p_photo_url,
        updated_at     = NOW()
    WHERE id      = p_id
      AND user_id = auth.uid();

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Log not found or not owned by current user';
    END IF;
END;
$$;
