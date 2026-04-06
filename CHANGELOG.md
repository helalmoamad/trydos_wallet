## 0.0.2

* Fix transactions pagination freeze in wallet home screen by deferring load-more dispatch to post-frame scheduling to avoid Build scheduled during frame assertions with overscroll/stretch physics.
* Prevent duplicate/re-entrant load-more triggers at list end by adding queue and lock guards for the same frame/viewport state.
* Move pagination lock reset logic out of build phase into bloc listener flow to avoid side effects during layout/paint.

## 0.0.1

* TODO: Describe initial release.
