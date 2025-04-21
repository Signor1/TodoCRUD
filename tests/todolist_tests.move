#[test_only]
module todolist::todolist_tests;
// uncomment this line to import the module
// use todolist::todolist;

const ENotImplemented: u64 = 0;

#[test]
fun test_todolist() {
    // pass
}

#[test, expected_failure(abort_code = ::todolist::todolist_tests::ENotImplemented)]
fun test_todolist_fail() {
    abort ENotImplemented
}
