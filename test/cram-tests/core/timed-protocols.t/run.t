Basic timed protocol
  $ nuscr --show-global-type Basic TimedBasic.nuscr
  Test1() from A to B;
  Test1() from B to C;
  Test5(payload) from A to B;
  Test2(integer) from A to B;
  (end)

Timed protocol with choice
  $ nuscr --show-global-type Choice TimedChoice.nuscr
  choice at A {
    ok() from A to B;
    (end)
  } or {
    quit() from A to B;
    (end)
  }

Timed protocol with recursion
  $ nuscr --show-global-type Recursion TimedRecursion.nuscr
  rec t {
    msg() from A to B;
    continue t;
  }

Timed two-buyer protocol
  $ nuscr --show-global-type TwoBuyer TimedTwoBuyer.nuscr
  s(string) from B1 to S;
  b1(int) from S to B1;
  b2(int) from S to B2;
  bi2(int) from B1 to B2;
  choice at B2 {
    ok() from B2 to S;
    s(string) from B2 to S;
    b2(string) from S to B2;
    (end)
  } or {
    quit() from B2 to S;
    (end)
  }
