  $ nuscr --gencode-rust=GCS@CommandInt CommandInt.nuscr
  #[derive(Debug, Clone, Copy, PartialEq, Eq)]
  enum State {
      S0,
      S2,
  }
  
  #[derive(Debug, Clone, Copy, PartialEq, Eq)]
  enum Role {
      FC,
  }
  
  #[derive(Debug, Clone, Copy, PartialEq, Eq)]
  enum Label {
      COMMAND_ACK,
      COMMAND_INT,
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
              (State::S0, Direction::Send, Role::FC, Label::COMMAND_INT) => { self.state = State::S2; true }
              (State::S2, Direction::Recv, Role::FC, Label::COMMAND_ACK) => { self.state = State::S0; true }
              _ => false,
          }
      }
  
      fn is_terminal(&self) -> bool {
          false
      }
  }

  $ nuscr --gencode-rust=FC@CommandInt CommandInt.nuscr
  #[derive(Debug, Clone, Copy, PartialEq, Eq)]
  enum State {
      S0,
      S2,
  }
  
  #[derive(Debug, Clone, Copy, PartialEq, Eq)]
  enum Role {
      GCS,
  }
  
  #[derive(Debug, Clone, Copy, PartialEq, Eq)]
  enum Label {
      COMMAND_ACK,
      COMMAND_INT,
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
              (State::S0, Direction::Recv, Role::GCS, Label::COMMAND_INT) => { self.state = State::S2; true }
              (State::S2, Direction::Send, Role::GCS, Label::COMMAND_ACK) => { self.state = State::S0; true }
              _ => false,
          }
      }
  
      fn is_terminal(&self) -> bool {
          false
      }
  }

  $ nuscr --gencode-rust=GCS@CommandLong CommandLong.nuscr
  #[derive(Debug, Clone, Copy, PartialEq, Eq)]
  enum State {
      S0,
      S2,
  }
  
  #[derive(Debug, Clone, Copy, PartialEq, Eq)]
  enum Role {
      FC,
  }
  
  #[derive(Debug, Clone, Copy, PartialEq, Eq)]
  enum Label {
      COMMAND_ACK,
      COMMAND_LONG,
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
              (State::S0, Direction::Send, Role::FC, Label::COMMAND_LONG) => { self.state = State::S2; true }
              (State::S2, Direction::Recv, Role::FC, Label::COMMAND_ACK) => { self.state = State::S0; true }
              _ => false,
          }
      }
  
      fn is_terminal(&self) -> bool {
          false
      }
  }

  $ nuscr --gencode-rust=FC@CommandLong CommandLong.nuscr
  #[derive(Debug, Clone, Copy, PartialEq, Eq)]
  enum State {
      S0,
      S2,
  }
  
  #[derive(Debug, Clone, Copy, PartialEq, Eq)]
  enum Role {
      GCS,
  }
  
  #[derive(Debug, Clone, Copy, PartialEq, Eq)]
  enum Label {
      COMMAND_ACK,
      COMMAND_LONG,
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
              (State::S0, Direction::Recv, Role::GCS, Label::COMMAND_LONG) => { self.state = State::S2; true }
              (State::S2, Direction::Send, Role::GCS, Label::COMMAND_ACK) => { self.state = State::S0; true }
              _ => false,
          }
      }
  
      fn is_terminal(&self) -> bool {
          false
      }
  }
