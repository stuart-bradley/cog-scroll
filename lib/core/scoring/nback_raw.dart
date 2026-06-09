/// The raw input for the `nback` metric: round-end accuracy (`acc`, %) and the
/// level reached (`n`). Mirrors the prototype's `{ acc, n }` object.
///
/// Accuracy is lifted by the level (`eff = acc + (n - 2) * 15`) before
/// normalization, so reaching a higher N is rewarded.
typedef NbackRaw = ({int acc, int n});
