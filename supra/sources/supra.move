module OracleOnSui::PriceOracle {
  use sui::object::UID;
  use sui::vec_map::VecMap;
  use std::string::String;
  
  struct Entry has store, copy, drop {
    value: String,
  }
  
  struct OracleHolder has key, store {
    id: UID,
    feeds: VecMap<String, Entry>,
  }
  
  native public fun get_price(_oracle_holder: &OracleHolder, _symbol_byts: vector<u8>): String;
}