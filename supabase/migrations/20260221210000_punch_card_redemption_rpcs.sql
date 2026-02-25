-- redeem_punch_card: only a manager of the business that owns the punch program can redeem.
-- list_punch_card_enrollments_for_business: managers can list enrollments for their business.
-- Requires: is_business_manager(user_id, business_id), user_punch_cards, punch_card_programs, profiles.

CREATE OR REPLACE FUNCTION public.redeem_punch_card(p_card_id uuid, p_redeemed_by uuid)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_row record;
  v_program record;
  v_business_id uuid;
BEGIN
  SELECT id, user_id, program_id, current_punches, is_redeemed
    INTO v_row
    FROM user_punch_cards
    WHERE id = p_card_id
    FOR UPDATE;
  IF NOT FOUND THEN
    RETURN jsonb_build_object('ok', false, 'error', 'Card not found');
  END IF;
  IF v_row.is_redeemed THEN
    RETURN jsonb_build_object('ok', false, 'error', 'Already redeemed');
  END IF;

  SELECT business_id, punches_required INTO v_program
    FROM punch_card_programs
    WHERE id = v_row.program_id;
  IF NOT FOUND THEN
    RETURN jsonb_build_object('ok', false, 'error', 'Program not found');
  END IF;
  v_business_id := v_program.business_id;

  IF v_row.current_punches < v_program.punches_required THEN
    RETURN jsonb_build_object('ok', false, 'error', 'Card not full');
  END IF;
  IF NOT is_business_manager(p_redeemed_by, v_business_id) THEN
    RETURN jsonb_build_object('ok', false, 'error', 'Not a manager of this business');
  END IF;

  UPDATE user_punch_cards
  SET is_redeemed = true, redeemed_at = now()
  WHERE id = p_card_id;
  RETURN jsonb_build_object('ok', true);
END;
$$;
-- List enrollments for a business; caller must be manager of that business.
CREATE OR REPLACE FUNCTION public.list_punch_card_enrollments_for_business(p_business_id uuid)
RETURNS TABLE (
  user_punch_card_id uuid,
  program_id text,
  program_title text,
  punches_required int,
  current_punches int,
  is_redeemed boolean,
  user_display_name text,
  user_email text
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NOT is_business_manager(auth.uid(), p_business_id) THEN
    RAISE EXCEPTION 'Not a manager of this business';
  END IF;
  RETURN QUERY
  SELECT
    upc.id AS user_punch_card_id,
    upc.program_id::text AS program_id,
    COALESCE(p.title, p.reward_description, '')::text AS program_title,
    p.punches_required,
    upc.current_punches,
    upc.is_redeemed,
    COALESCE(pr.display_name, pr.email, upc.user_id::text)::text AS user_display_name,
    pr.email::text AS user_email
  FROM user_punch_cards upc
  JOIN punch_card_programs p ON p.id = upc.program_id AND p.business_id = p_business_id
  LEFT JOIN profiles pr ON pr.user_id = upc.user_id
  ORDER BY upc.created_at DESC;
END;
$$;
