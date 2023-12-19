module allin_oracle::pyth_parser {
    use sui::clock::Clock;
    use sui::event::emit;
    use sui::object::{ID};

    use pyth::pyth;
    use pyth::state::{Self, State as PythState};
    use pyth::price_info::{Self, PriceInfoObject};
    use pyth::price::{Self, Price};
    use pyth::price_feed;

    use pyth::i64::{Self, I64};

    friend allin_oracle::oracle;

    entry fun get_price_info_object_id(state: &PythState, price_identifier_bytes: vector<u8>) {
        let id = state::get_price_info_object_id(state, price_identifier_bytes);
        emit(PythPriceInfoObject{ id });
    }

    public(friend) entry fun get_price(
        state: &PythState,
        price_info_object: &PriceInfoObject,
        clock: &Clock
    ): (u64, u64) {

        let price_result: Price = pyth::get_price(state, price_info_object, clock);

        let price: I64 = price::get_price(&price_result);
        let expo: I64 = price::get_expo(&price_result);
        let conf = price::get_conf(&price_result);
        let timestamp = price::get_timestamp(&price_result);

        let price = i64::get_magnitude_if_positive(&price);
        let decimal = i64::get_magnitude_if_negative(&expo);
        // price * (10^expo) => expo = -decimal

        emit(PythPrice{price, conf, timestamp, decimal});
        (price, decimal)
    }

    public(friend) entry fun get_ema_price(
        price_info_object: &PriceInfoObject
    ): (u64, u64, u64) {
        let price_info = price_info::get_price_info_from_price_info_object(price_info_object);
        let price_result: Price = price_feed::get_price(price_info::get_price_feed(&price_info));

        let price: I64 = price::get_price(&price_result);
        let expo: I64 = price::get_expo(&price_result);
        let conf = price::get_conf(&price_result);
        let timestamp = price::get_timestamp(&price_result);

        let price = i64::get_magnitude_if_positive(&price);
        let decimal = i64::get_magnitude_if_negative(&expo);
        // price * (10^expo) => expo = -decimal

        emit(PythPrice{price, conf, timestamp, decimal});
        (price, decimal, timestamp)
    }

    struct PythPriceInfoObject has copy, drop {
        id: ID
    }

    struct PythPrice has copy, drop {
        price: u64,
        conf: u64,
        timestamp: u64,
        decimal: u64,
    }
}