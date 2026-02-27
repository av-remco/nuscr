Basic timed protocol
  $ nuscr --show-global-type Basic TimedBasic.nuscr
  Test1() from A to B within [0;2] using a and resetting ();
  Test1() from B to C within [0;2] using a and resetting ();
  Test5(payload) from A to B within [0;2] using a and resetting ();
  Test2(integer) from A to B within [0;2] using a and resetting (a);
  (end)

Timed protocol with choice
  $ nuscr --show-global-type Choice TimedChoice.nuscr
  choice at A {
    ok() from A to B within [0;1] using c and resetting ();
    (end)
  } or {
    quit() from A to B within [0;1] using c and resetting (c);
    (end)
  }

Timed protocol with recursion
  $ nuscr --show-global-type Recursion TimedRecursion.nuscr
  rec t {
    msg() from A to B within [0;1] using c and resetting ();
    continue t;
  }

Timed two-buyer protocol
  $ nuscr --show-global-type TwoBuyer TimedTwoBuyer.nuscr
  s(string) from B1 to S within [0;1] using c and resetting ();
  b1(int) from S to B1 within [0;1] using c and resetting ();
  b2(int) from S to B2 within [0;1] using c and resetting ();
  bi2(int) from B1 to B2 within [0;1] using c and resetting ();
  choice at B2 {
    ok() from B2 to S within [0;1] using c and resetting ();
    s(string) from B2 to S within [0;1] using c and resetting ();
    b2(string) from S to B2 within [0;1] using c and resetting ();
    (end)
  } or {
    quit() from B2 to S within [0;1] using c and resetting ();
    (end)
  }

Projection of basic timed protocol
  $ nuscr --project A@Basic TimedBasic.nuscr
  Test1() to B within [0;2] using a and resetting ();
  Test5(payload) to B within [0;2] using a and resetting ();
  Test2(integer) to B within [0;2] using a and resetting (a);
  (end)

  $ nuscr --project B@Basic TimedBasic.nuscr
  Test1() from A within [0;2] using a and resetting ();
  Test1() to C within [0;2] using a and resetting ();
  Test5(payload) from A within [0;2] using a and resetting ();
  Test2(integer) from A within [0;2] using a and resetting (a);
  (end)

  $ nuscr --project C@Basic TimedBasic.nuscr
  Test1() from B within [0;2] using a and resetting ();
  (end)

Projection of timed choice
  $ nuscr --project A@Choice TimedChoice.nuscr
  choice at A {
    ok() to B within [0;1] using c and resetting ();
    (end)
  } or {
    quit() to B within [0;1] using c and resetting (c);
    (end)
  }

  $ nuscr --project B@Choice TimedChoice.nuscr
  choice at A {
    ok() from A within [0;1] using c and resetting ();
    (end)
  } or {
    quit() from A within [0;1] using c and resetting (c);
    (end)
  }

Projection of timed recursion
  $ nuscr --project A@Recursion TimedRecursion.nuscr
  rec t {
    msg() to B within [0;1] using c and resetting ();
    continue t;
  }

  $ nuscr --project B@Recursion TimedRecursion.nuscr
  rec t {
    msg() from A within [0;1] using c and resetting ();
    continue t;
  }

Projection of timed two-buyer
  $ nuscr --project B1@TwoBuyer TimedTwoBuyer.nuscr
  s(string) to S within [0;1] using c and resetting ();
  b1(int) from S within [0;1] using c and resetting ();
  bi2(int) to B2 within [0;1] using c and resetting ();
  (end)

  $ nuscr --project B2@TwoBuyer TimedTwoBuyer.nuscr
  b2(int) from S within [0;1] using c and resetting ();
  bi2(int) from B1 within [0;1] using c and resetting ();
  choice at B2 {
    ok() to S within [0;1] using c and resetting ();
    s(string) to S within [0;1] using c and resetting ();
    b2(string) from S within [0;1] using c and resetting ();
    (end)
  } or {
    quit() to S within [0;1] using c and resetting ();
    (end)
  }

  $ nuscr --project S@TwoBuyer TimedTwoBuyer.nuscr
  s(string) from B1 within [0;1] using c and resetting ();
  b1(int) to B1 within [0;1] using c and resetting ();
  b2(int) to B2 within [0;1] using c and resetting ();
  choice at B2 {
    ok() from B2 within [0;1] using c and resetting ();
    s(string) from B2 within [0;1] using c and resetting ();
    b2(string) to B2 within [0;1] using c and resetting ();
    (end)
  } or {
    quit() from B2 within [0;1] using c and resetting ();
    (end)
  }
