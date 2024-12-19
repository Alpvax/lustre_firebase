// /// Creates a new immutable instance of {@link Query} that is extended to also
// /// include additional query constraints.
// ///
// /// @param query - The {@link Query} instance to use as a base for the new
// /// constraints.
// /// @param compositeFilter - The {@link QueryCompositeFilterConstraint} to
// /// apply. Create {@link QueryCompositeFilterConstraint} using {@link and} or
// /// {@link or}.
// /// @param queryConstraints - Additional {@link QueryNonFilterConstraint}s to
// /// apply (e.g. {@link orderBy}, {@link limit}).
// /// @throws if any of the provided query constraints cannot be combined with the
// /// existing or new constraints.
// @external(javascript, "../../firestore.ffi.mjs", "query")
// pub fn query(query: Query(a), composite_filter: QueryCompositeFilterConstraint, query_constraints: List(QueryNonFilterConstraint)) -> Query(a)

// /// Creates a new immutable instance of {@link Query} that is extended to also
// /// include additional query constraints.
// ///
// /// @param query - The {@link Query} instance to use as a base for the new
// /// constraints.
// /// @param queryConstraints - The list of {@link QueryConstraint}s to apply.
// /// @throws if any of the provided query constraints cannot be combined with the
// /// existing or new constraints.
// @external(javascript, "../../firestore.ffi.mjs", "query")
// pub fn query(query: Query(a), queryConstraints: List(QueryConstraint)) -> Query(a)
