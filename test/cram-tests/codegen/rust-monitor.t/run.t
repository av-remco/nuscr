Single protocol monitor generation
  $ nuscr --gencode-rust-monitor A SingleProto.nuscr
  use std::collections::HashMap;
  
  #[derive(Debug, Clone, Copy, PartialEq, Eq)]
  pub enum Direction {
      Send,
      Recv,
  }
  
  #[derive(Debug, Clone)]
  pub struct Action {
      pub dir: Direction,
      pub role: String,
      pub label: String,
  }
  
  #[derive(Debug, Clone, Copy, PartialEq, Eq, Hash)]
  pub enum ProtocolType {
      Ping,
  }
  
  mod ping {
      use super::*;
  
      #[derive(Debug, Clone, Copy, PartialEq, Eq)]
      pub enum State {
          S0,
          S1,
          S2,
      }
  
      #[derive(Debug)]
      pub struct Monitor {
          state: State,
      }
  
      impl Monitor {
          pub fn new() -> Self {
              Self { state: State::S0 }
          }
  
          pub fn step(&mut self, action: &Action) -> bool {
              match (self.state, action.dir, action.role.as_str(), action.label.as_str()) {
                  (State::S0, Direction::Send, "B", "ping") => {
                      self.state = State::S1;
                      true
                  }
                  (State::S1, Direction::Recv, "B", "pong") => {
                      self.state = State::S2;
                      true
                  }
                  _ => false,
              }
          }
  
          pub fn is_terminal(&self) -> bool {
              matches!(self.state, State::S2)
          }
  
          pub fn is_initiating(action: &Action) -> bool {
              matches!((action.dir, action.role.as_str(), action.label.as_str()),
                  (Direction::Send, "B", "ping")
              )
          }
      }
  }
  
  fn route(dir: Direction, role: &str, label: &str) -> Option<ProtocolType> {
      match (dir, role, label) {
          (Direction::Recv, "B", "pong") => Some(ProtocolType::Ping),
          (Direction::Send, "B", "ping") => Some(ProtocolType::Ping),
          _ => None,
      }
  }
  
  fn initiating(dir: Direction, role: &str, label: &str) -> Option<ProtocolType> {
      match (dir, role, label) {
          (Direction::Send, "B", "ping") => Some(ProtocolType::Ping),
          _ => None,
      }
  }
  
  #[derive(Debug)]
  pub enum MonitorError {
      ConcurrentSameType(ProtocolType),
      UncorrelatedMessage,
      ProtocolViolation(ProtocolType),
  }
  
  #[derive(Debug)]
  enum MonitorInstance {
      Ping(ping::Monitor),
  }
  
  impl MonitorInstance {
      fn new(proto: ProtocolType) -> Self {
          match proto {
              ProtocolType::Ping => MonitorInstance::Ping(ping::Monitor::new()),
          }
      }
  
      fn step(&mut self, action: &Action) -> bool {
          match self {
              MonitorInstance::Ping(m) => m.step(action),
          }
      }
  
      fn is_terminal(&self) -> bool {
          match self {
              MonitorInstance::Ping(m) => m.is_terminal(),
          }
      }
  }
  
  #[derive(Debug)]
  pub struct Dispatcher {
      monitors: HashMap<(u8, u8, ProtocolType), MonitorInstance>,
  }
  
  impl Dispatcher {
      pub fn new() -> Self {
          Self { monitors: HashMap::new() }
      }
  
      pub fn dispatch(
          &mut self,
          sys_id: u8,
          comp_id: u8,
          action: &Action,
      ) -> Result<(), MonitorError> {
          let proto = match route(action.dir, &action.role, &action.label) {
              Some(p) => p,
              None => return Err(MonitorError::UncorrelatedMessage),
          };
          let key = (sys_id, comp_id, proto);
          if let Some(monitor) = self.monitors.get_mut(&key) {
              if !monitor.step(action) {
                  if initiating(action.dir, &action.role, &action.label).is_some() {
                      return Err(MonitorError::ConcurrentSameType(proto));
                  }
                  return Err(MonitorError::ProtocolViolation(proto));
              }
              if monitor.is_terminal() {
                  self.monitors.remove(&key);
              }
          } else {
              if initiating(action.dir, &action.role, &action.label).is_none() {
                  return Err(MonitorError::UncorrelatedMessage);
              }
              let mut monitor = MonitorInstance::new(proto);
              monitor.step(action);
              if !monitor.is_terminal() {
                  self.monitors.insert(key, monitor);
              }
          }
          Ok(())
      }
  }




















