#include "features/achordion.h"

void matrix_scan_user(void) {
  achordion_task();
}

bool achordion_chord(uint16_t tap_hold_keycode,
                     keyrecord_t* tap_hold_record,
                     uint16_t other_keycode,
                     keyrecord_t* other_record) {
  // Exceptionally consider the following chords as holds, even though they
  // are on the same hand in Dvorak.
  switch (tap_hold_keycode) {
    case MT(MOD_LGUI, KC_D):
      if (other_keycode == KC_TAB) { return true; }
      if (other_keycode == KC_Z) { return true; }
      if (other_keycode == KC_R) { return true; }
      if (other_keycode == KC_T) { return true; }
      if (other_keycode == KC_W) { return true; }
      break;
    case MT(MOD_RSFT, KC_J):
      if (other_keycode == MT(MOD_RCTL, KC_SCLN)) { return true; }
      break;
  }

  // Also allow same-hand holds when the other key is in the rows below the
  // alphas. I need the `% (MATRIX_ROWS / 2)` because my keyboard is split.
  // if (tap_hold_record->event.key.row % (MATRIX_ROWS / 2) >= 5) { return true; }

  return achordion_opposite_hands(tap_hold_record, other_record);
}

uint16_t achordion_timeout(uint16_t tap_hold_keycode) {
  switch (tap_hold_keycode) {
    case MT(MOD_LGUI, KC_GRAVE):
    case KC_RIGHT_SHIFT:
    case MT(MOD_LCTL, KC_ESCAPE):

    case LT(1,KC_BSPC):
    case LT(1,KC_SPACE):
    case LT(2,KC_BSPC):

    case MO(1):
    case MO(2):
    case MO(3):

      return 0;
  }

  return 700;  // Otherwise use a timeout of 700 ms.
}

bool achordion_eager_mod(uint8_t mod) {
  return true;  // Eagerly apply all mods.
}

uint16_t achordion_streak_chord_timeout(
    uint16_t tap_hold_keycode, uint16_t next_keycode) {
  if (IS_QK_LAYER_TAP(tap_hold_keycode)) {
    return 0;  // Disable streak detection on layer-tap keys.
  }

  // Otherwise, tap_hold_keycode is a mod-tap key.
  uint8_t mod = mod_config(QK_MOD_TAP_GET_MODS(tap_hold_keycode));
  if ((mod & MOD_LSFT) != 0) {
    return 50;  // A shorter streak timeout for Shift mod-tap keys.
  } else {
    return 100;  // A longer timeout otherwise.
  }
}
