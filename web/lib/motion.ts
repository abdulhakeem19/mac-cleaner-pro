import type { Variants, Transition } from "framer-motion";

/**
 * Reusable easing + duration tokens. Mirrors the prototype's
 * cubic-bezier(.22, 1, .36, 1) "out-quint-ish" easing.
 */
export const ease = [0.22, 1, 0.36, 1] as const;
export const easeOvershoot = [0.34, 1.56, 0.64, 1] as const;

export const tDefault: Transition = { duration: 0.75, ease };
export const tSlow: Transition = { duration: 0.9, ease };
export const tBouncy: Transition = { duration: 0.7, ease: easeOvershoot };

export const fadeUp: Variants = {
  hidden: { opacity: 0, y: 40 },
  show: { opacity: 1, y: 0 },
};

export const fadeDown: Variants = {
  hidden: { opacity: 0, y: -28 },
  show: { opacity: 1, y: 0 },
};

export const fadeLeft: Variants = {
  hidden: { opacity: 0, x: 40 },
  show: { opacity: 1, x: 0 },
};

export const blurIn: Variants = {
  hidden: { opacity: 0, filter: "blur(12px)", y: 16 },
  show: { opacity: 1, filter: "blur(0px)", y: 0 },
};

export const scaleUp: Variants = {
  hidden: { opacity: 0, scale: 0.88 },
  show: { opacity: 1, scale: 1 },
};

export const stagger = (children = 0.08, delay = 0): Variants => ({
  hidden: {},
  show: { transition: { staggerChildren: children, delayChildren: delay } },
});

/** Common viewport options so all sections trigger at the same point. */
export const viewport = { once: true, margin: "0px 0px -30px 0px" } as const;
