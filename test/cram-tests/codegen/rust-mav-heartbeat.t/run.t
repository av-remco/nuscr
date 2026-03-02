  $ nuscr --gencode-rust=Sender@Heartbeat Heartbeat.nuscr
  #[derive(Debug, Clone, Copy, PartialEq, Eq)]
  enum State {
      S0,
  }
  
  #[derive(Debug, Clone, Copy, PartialEq, Eq)]
  enum Role {
      Receiver,
  }
  
  #[derive(Debug, Clone, Copy, PartialEq, Eq)]
  enum Label {
      HEARTBEAT,
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
              (State::S0, Direction::Send, Role::Receiver, Label::HEARTBEAT) => { self.state = State::S0; true }
              _ => false,
          }
      }
  
      fn is_terminal(&self) -> bool {
          false
      }
  }

  $ nuscr --gencode-rust=Receiver@Heartbeat Heartbeat.nuscr
  #[derive(Debug, Clone, Copy, PartialEq, Eq)]
  enum State {
      S0,
  }
  
  #[derive(Debug, Clone, Copy, PartialEq, Eq)]
  enum Role {
      Sender,
  }
  
  #[derive(Debug, Clone, Copy, PartialEq, Eq)]
  enum Label {
      HEARTBEAT,
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
              (State::S0, Direction::Recv, Role::Sender, Label::HEARTBEAT) => { self.state = State::S0; true }
              _ => false,
          }
      }
  
      fn is_terminal(&self) -> bool {
          false
      }
  }
