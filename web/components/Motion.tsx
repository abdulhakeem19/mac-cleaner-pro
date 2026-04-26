"use client";

import { m, useReducedMotion, type HTMLMotionProps } from "framer-motion";
import {
  blurIn,
  ease,
  fadeLeft,
  fadeUp,
  scaleUp,
  stagger,
  tDefault,
  tBouncy,
  tSlow,
  viewport,
} from "@/lib/motion";

type MotionDivProps = HTMLMotionProps<"div"> & { delay?: number };

/**
 * Drop-in replacements for the prototype's data-motion attributes.
 * `delay` is in stagger ticks (0.08s each) to match the prototype's data-delay scale.
 */
export function FadeUp({ delay = 0, transition, ...rest }: MotionDivProps) {
  const reduce = useReducedMotion();
  return (
    <m.div
      variants={fadeUp}
      initial={reduce ? "show" : "hidden"}
      whileInView="show"
      viewport={viewport}
      transition={{ ...tDefault, delay: delay * 0.08, ...transition }}
      {...rest}
    />
  );
}

export function FadeLeft({ delay = 0, transition, ...rest }: MotionDivProps) {
  const reduce = useReducedMotion();
  return (
    <m.div
      variants={fadeLeft}
      initial={reduce ? "show" : "hidden"}
      whileInView="show"
      viewport={viewport}
      transition={{ ...tDefault, delay: delay * 0.08, ...transition }}
      {...rest}
    />
  );
}

export function BlurIn({ delay = 0, transition, ...rest }: MotionDivProps) {
  const reduce = useReducedMotion();
  return (
    <m.div
      variants={blurIn}
      initial={reduce ? "show" : "hidden"}
      whileInView="show"
      viewport={viewport}
      transition={{ ...tSlow, delay: delay * 0.08, ...transition }}
      {...rest}
    />
  );
}

export function ScaleUp({ delay = 0, transition, ...rest }: MotionDivProps) {
  const reduce = useReducedMotion();
  return (
    <m.div
      variants={scaleUp}
      initial={reduce ? "show" : "hidden"}
      whileInView="show"
      viewport={viewport}
      transition={{ ...tBouncy, delay: delay * 0.08, ...transition }}
      {...rest}
    />
  );
}

/**
 * Staggered container: children that use `Item` will animate in sequence.
 * Used for grids of cards.
 */
export function Stagger({
  delay = 0,
  step = 0.08,
  ...rest
}: MotionDivProps & { step?: number }) {
  const reduce = useReducedMotion();
  return (
    <m.div
      variants={stagger(reduce ? 0 : step, reduce ? 0 : delay)}
      initial={reduce ? "show" : "hidden"}
      whileInView="show"
      viewport={viewport}
      {...rest}
    />
  );
}

export function StaggerItem({ transition, ...rest }: MotionDivProps) {
  return (
    <m.div
      variants={fadeUp}
      transition={{ duration: 0.6, ease }}
      {...rest}
    />
  );
}
