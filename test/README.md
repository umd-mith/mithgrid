Testing
=======

The following conventions should be observed when writing tests.

* Prefix the name of a Data.initStore or Data.initView with the module in which the tests are running.  When possible, use a new name for each set of related tests.  This ensures that bugs tickled by one set of tests don't corrupt another set of tests. (see http://martinfowler.com/articles/nonDeterminism.html)

