/// CogScroll's motion-led feedback language: the five controller-driven motions
/// plus their facade (M1; DESIGN §3 / SPEC §3.7). Import this barrel to pull in
/// the whole motion system.
///
/// `MotionDriver` is deliberately NOT exported: it is the package-internal
/// lifecycle primitive the five wrappers share. Keeping it off the public
/// surface stops callers building a custom motion that forgets to render its
/// `child`, which would break the "stimulus stays visible" guarantee.
library;

export 'bloom.dart';
export 'feedback.dart';
export 'motion_specs.dart';
export 'pop.dart';
export 'pulse.dart';
export 'shake.dart';
export 'surge.dart';
