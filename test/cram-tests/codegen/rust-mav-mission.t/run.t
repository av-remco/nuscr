  $ nuscr --gencode-rust=GCS@MissionUpload MissionUpload.nuscr
  #[derive(Debug, Clone, Copy, PartialEq, Eq)]
  enum State {
      S0,
      S2,
      S5,
  }
  
  #[derive(Debug, Clone, Copy, PartialEq, Eq)]
  enum Role {
      FC,
  }
  
  #[derive(Debug, Clone, Copy, PartialEq, Eq)]
  enum Label {
      MISSION_ACK,
      MISSION_COUNT,
      MISSION_ITEM_INT,
      MISSION_REQUEST_INT,
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
              (State::S0, Direction::Send, Role::FC, Label::MISSION_COUNT) => { self.state = State::S2; true }
              (State::S2, Direction::Recv, Role::FC, Label::MISSION_ACK) => { self.state = State::S0; true }
              (State::S2, Direction::Recv, Role::FC, Label::MISSION_REQUEST_INT) => { self.state = State::S5; true }
              (State::S5, Direction::Send, Role::FC, Label::MISSION_ITEM_INT) => { self.state = State::S2; true }
              _ => false,
          }
      }
  
      fn is_terminal(&self) -> bool {
          false
      }
  }

  $ nuscr --gencode-rust=FC@MissionUpload MissionUpload.nuscr
  #[derive(Debug, Clone, Copy, PartialEq, Eq)]
  enum State {
      S0,
      S2,
      S5,
  }
  
  #[derive(Debug, Clone, Copy, PartialEq, Eq)]
  enum Role {
      GCS,
  }
  
  #[derive(Debug, Clone, Copy, PartialEq, Eq)]
  enum Label {
      MISSION_ACK,
      MISSION_COUNT,
      MISSION_ITEM_INT,
      MISSION_REQUEST_INT,
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
              (State::S0, Direction::Recv, Role::GCS, Label::MISSION_COUNT) => { self.state = State::S2; true }
              (State::S2, Direction::Send, Role::GCS, Label::MISSION_ACK) => { self.state = State::S0; true }
              (State::S2, Direction::Send, Role::GCS, Label::MISSION_REQUEST_INT) => { self.state = State::S5; true }
              (State::S5, Direction::Recv, Role::GCS, Label::MISSION_ITEM_INT) => { self.state = State::S2; true }
              _ => false,
          }
      }
  
      fn is_terminal(&self) -> bool {
          false
      }
  }

  $ nuscr --gencode-rust=GCS@MissionDownload MissionDownload.nuscr
  #[derive(Debug, Clone, Copy, PartialEq, Eq)]
  enum State {
      S0,
      S2,
      S3,
      S6,
  }
  
  #[derive(Debug, Clone, Copy, PartialEq, Eq)]
  enum Role {
      FC,
  }
  
  #[derive(Debug, Clone, Copy, PartialEq, Eq)]
  enum Label {
      MISSION_ACK,
      MISSION_COUNT,
      MISSION_ITEM_INT,
      MISSION_REQUEST_INT,
      MISSION_REQUEST_LIST,
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
              (State::S0, Direction::Send, Role::FC, Label::MISSION_REQUEST_LIST) => { self.state = State::S2; true }
              (State::S2, Direction::Recv, Role::FC, Label::MISSION_COUNT) => { self.state = State::S3; true }
              (State::S3, Direction::Send, Role::FC, Label::MISSION_ACK) => { self.state = State::S0; true }
              (State::S3, Direction::Send, Role::FC, Label::MISSION_REQUEST_INT) => { self.state = State::S6; true }
              (State::S6, Direction::Recv, Role::FC, Label::MISSION_ITEM_INT) => { self.state = State::S3; true }
              _ => false,
          }
      }
  
      fn is_terminal(&self) -> bool {
          false
      }
  }

  $ nuscr --gencode-rust=GCS@MissionDownload MissionDownload.nuscr
  #[derive(Debug, Clone, Copy, PartialEq, Eq)]
  enum State {
      S0,
      S2,
      S3,
      S6,
  }
  
  #[derive(Debug, Clone, Copy, PartialEq, Eq)]
  enum Role {
      FC,
  }
  
  #[derive(Debug, Clone, Copy, PartialEq, Eq)]
  enum Label {
      MISSION_ACK,
      MISSION_COUNT,
      MISSION_ITEM_INT,
      MISSION_REQUEST_INT,
      MISSION_REQUEST_LIST,
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
              (State::S0, Direction::Send, Role::FC, Label::MISSION_REQUEST_LIST) => { self.state = State::S2; true }
              (State::S2, Direction::Recv, Role::FC, Label::MISSION_COUNT) => { self.state = State::S3; true }
              (State::S3, Direction::Send, Role::FC, Label::MISSION_ACK) => { self.state = State::S0; true }
              (State::S3, Direction::Send, Role::FC, Label::MISSION_REQUEST_INT) => { self.state = State::S6; true }
              (State::S6, Direction::Recv, Role::FC, Label::MISSION_ITEM_INT) => { self.state = State::S3; true }
              _ => false,
          }
      }
  
      fn is_terminal(&self) -> bool {
          false
      }
  }
