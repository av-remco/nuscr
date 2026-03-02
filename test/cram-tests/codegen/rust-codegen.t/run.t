Rust monitor codegen for role C:
  $ nuscr --gencode-rust=C@Adder Adder.nuscr
  #[derive(Debug, Clone, Copy, PartialEq, Eq)]
  enum State {
      S0,
      S3,
      S4,
      S6,
      S7,
  }
  
  #[derive(Debug, Clone, Copy, PartialEq, Eq)]
  enum Role {
      S,
  }
  
  #[derive(Debug, Clone, Copy, PartialEq, Eq)]
  enum Label {
      Add,
      Bye,
      Sum,
  }
  
  #[derive(Debug, Clone, Copy, PartialEq, Eq)]
  enum Direction {
      Send,
      Recv,
  }
  
  #[derive(Debug, Clone, PartialEq)]
  struct Value;
  
  struct Memory;
  
  impl Memory {
      fn new() -> Self {
          Self
      }
  }
  
  #[derive(Debug, Clone, PartialEq)]
  struct Action {
      dir: Direction,
      role: Role,
      label: Label,
      payloads: Vec<Value>,
  }
  
  struct Monitor {
      state: State,
      memory: Memory,
  }
  
  impl Monitor {
      fn new() -> Self {
          Self { state: State::S0, memory: Memory::new() }
      }
  
      fn step(&mut self, action: &Action) -> bool {
          match (self.state, action.dir, action.role, action.label) {
              (State::S0, Direction::Send, Role::S, Label::Add) => { self.state = State::S3; true }
              (State::S0, Direction::Send, Role::S, Label::Bye) => { self.state = State::S6; true }
              (State::S3, Direction::Send, Role::S, Label::Add) => { self.state = State::S4; true }
              (State::S4, Direction::Recv, Role::S, Label::Sum) => { self.state = State::S0; true }
              (State::S6, Direction::Recv, Role::S, Label::Bye) => { self.state = State::S7; true }
              _ => false,
          }
      }
  
      fn is_terminal(&self) -> bool {
          matches!(self.state, State::S7)
      }
  }












Rust monitor codegen for role S:
  $ nuscr --gencode-rust=S@Adder Adder.nuscr
  #[derive(Debug, Clone, Copy, PartialEq, Eq)]
  enum State {
      S0,
      S3,
      S4,
      S6,
      S7,
  }
  
  #[derive(Debug, Clone, Copy, PartialEq, Eq)]
  enum Role {
      C,
  }
  
  #[derive(Debug, Clone, Copy, PartialEq, Eq)]
  enum Label {
      Add,
      Bye,
      Sum,
  }
  
  #[derive(Debug, Clone, Copy, PartialEq, Eq)]
  enum Direction {
      Send,
      Recv,
  }
  
  #[derive(Debug, Clone, PartialEq)]
  struct Value;
  
  struct Memory;
  
  impl Memory {
      fn new() -> Self {
          Self
      }
  }
  
  #[derive(Debug, Clone, PartialEq)]
  struct Action {
      dir: Direction,
      role: Role,
      label: Label,
      payloads: Vec<Value>,
  }
  
  struct Monitor {
      state: State,
      memory: Memory,
  }
  
  impl Monitor {
      fn new() -> Self {
          Self { state: State::S0, memory: Memory::new() }
      }
  
      fn step(&mut self, action: &Action) -> bool {
          match (self.state, action.dir, action.role, action.label) {
              (State::S0, Direction::Recv, Role::C, Label::Add) => { self.state = State::S3; true }
              (State::S0, Direction::Recv, Role::C, Label::Bye) => { self.state = State::S6; true }
              (State::S3, Direction::Recv, Role::C, Label::Add) => { self.state = State::S4; true }
              (State::S4, Direction::Send, Role::C, Label::Sum) => { self.state = State::S0; true }
              (State::S6, Direction::Send, Role::C, Label::Bye) => { self.state = State::S7; true }
              _ => false,
          }
      }
  
      fn is_terminal(&self) -> bool {
          matches!(self.state, State::S7)
      }
  }











