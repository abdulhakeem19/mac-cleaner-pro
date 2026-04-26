"use client";

import {
  animate,
  m,
  useInView,
  useMotionValue,
  useReducedMotion,
  useTransform,
} from "framer-motion";
import { useEffect, useRef } from "react";

export function CountUp({
  to,
  decimals = 0,
  suffix = "",
  duration = 1.4,
}: {
  to: number;
  decimals?: number;
  suffix?: string;
  duration?: number;
}) {
  const reduce = useReducedMotion();
  const ref = useRef<HTMLSpanElement>(null);
  const inView = useInView(ref, { once: true, margin: "0px 0px -10% 0px" });
  const mv = useMotionValue(0);
  const text = useTransform(mv, (v) => v.toFixed(decimals) + suffix);

  useEffect(() => {
    if (!inView) return;
    if (reduce) {
      mv.set(to);
      return;
    }
    const controls = animate(mv, to, {
      duration,
      ease: [0.22, 1, 0.36, 1],
    });
    return () => controls.stop();
  }, [inView, to, duration, mv, reduce]);

  return <m.span ref={ref}>{text}</m.span>;
}
