"use client";
import { LazyMotion } from "framer-motion";
import type { ReactNode } from "react";

const loadFeatures = () =>
  import("@/lib/motionFeatures").then((r) => r.default);

export function MotionProvider({ children }: { children: ReactNode }) {
  return <LazyMotion features={loadFeatures}>{children}</LazyMotion>;
}
