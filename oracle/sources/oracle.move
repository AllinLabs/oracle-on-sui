module allin_oracle::oracle {
    use sui::tx_context::{Self, TxContext};
    use sui::object::{Self, UID, ID};
    use sui::transfer;
    use sui::event::emit;
    use sui::clock::{Self, Clock};
    use sui::math::pow;

    use std::type_name::{Self, TypeName};
    use std::ascii::String;
    use std::option::{Self, Option};

    // ======== Structs =========

    struct ManagerCap has key {
        id: UID,
    }

    struct Oracle has key {
        id: UID,
        base_token: String,
        quote_token: String,
        base_token_type: TypeName,
        quote_token_type: TypeName,
        decimal: u64,
        price: u64,
        twap_price: u64,
        ts_ms: u64,
        epoch: u64,
        time_interval: u64,
        switchboard: Option<ID>,
        pyth: Option<ID>,
    }

    // ======== Functions =========

    fun init(ctx: &mut TxContext) {
        transfer::transfer(
            ManagerCap {id: object::new(ctx)},
            tx_context::sender(ctx)
        );
    }

    #[test_only]
    public fun test_init(ctx: &mut TxContext) {
        init(ctx);
    }

    public entry fun new_oracle<B_TOKEN, Q_TOKEN>(
        _manager_cap: &ManagerCap,
        base_token: String,
        quote_token: String,
        decimal: u64,
        ctx: &mut TxContext
    ) {

        let id = object::new(ctx);

        let oracle = Oracle {
            id,
            base_token,
            quote_token,
            base_token_type: type_name::get<B_TOKEN>(),
            quote_token_type: type_name::get<Q_TOKEN>(),
            decimal,
            price: 0,
            twap_price: 0,
            ts_ms: 0,
            epoch: tx_context::epoch(ctx),
            time_interval: 300 * 1000,
            switchboard: option::none(),
            pyth: option::none(),
        };

        transfer::share_object(oracle);
    }

    public entry fun update(
        oracle: &mut Oracle,
        _manager_cap: &ManagerCap,
        price: u64,
        twap_price: u64,
        clock: &Clock,
        ctx: &mut TxContext
    ) {
        assert!(price > 0, E_INVALID_PRICE);
        assert!(twap_price > 0, E_INVALID_PRICE);

        let ts_ms = clock::timestamp_ms(clock);

        oracle.price = price;
        oracle.twap_price = twap_price;
        oracle.ts_ms = ts_ms;
        oracle.epoch = tx_context::epoch(ctx);

        emit(PriceEvent {id: object::id(oracle), price, ts_ms});
    }

    use switchboard_std::aggregator::{Aggregator};
    use allin_oracle::switchboard_feed_parser;

    entry fun update_switchboard_oracle(
        oracle: &mut Oracle,
        _manager_cap: &ManagerCap,
        feed: &Aggregator,
    ) {
        let id = object::id(feed);
        oracle.switchboard = option::some(id);
    }

    entry fun update_with_switchboard(
        oracle: &mut Oracle,
        feed: &Aggregator,
        clock: &Clock,
        ctx: &mut TxContext
    ) {
        assert!(option::is_some(&oracle.switchboard), E_NOT_SWITCHBOARD);
        assert!(option::borrow(&oracle.switchboard) == &object::id(feed), E_INVALID_SWITCHBOARD);

        let ts_ms = clock::timestamp_ms(clock);

        let (price_u128, decimal_u8) = switchboard_feed_parser::log_aggregator_info(feed);
        assert!(price_u128 > 0, E_INVALID_PRICE);

        let decimal = (decimal_u8 as u64);
        if (decimal > oracle.decimal) {
            price_u128 = price_u128 / (pow(10, ((decimal - oracle.decimal) as u8)) as u128);
        } else {
            price_u128 = price_u128 * (pow(10, ((oracle.decimal - decimal) as u8)) as u128);
        };

        let price = (price_u128 as u64);
        oracle.price = price;
        oracle.twap_price = price;
        oracle.ts_ms = ts_ms;
        oracle.epoch = tx_context::epoch(ctx);

        emit(PriceEvent {id: object::id(oracle), price, ts_ms});
    }

    use allin_oracle::pyth_parser;
    use pyth::state::{State as PythState};
    use pyth::price_info::{PriceInfoObject};

    entry fun update_pyth_oracle(
        oracle: &mut Oracle,
        _manager_cap: &ManagerCap,
        price_info_object: &PriceInfoObject,
    ) {
        let id = object::id(price_info_object);
        oracle.pyth = option::some(id);
    }

    entry fun update_with_pyth(
        oracle: &mut Oracle,
        state: &PythState,
        price_info_object: &PriceInfoObject,
        clock: &Clock,
        ctx: &mut TxContext
    ) {
        assert!(option::is_some(&oracle.pyth), E_NOT_PYTH);
        assert!(option::borrow(&oracle.pyth) == &object::id(price_info_object), E_INVALID_PYTH);

        let (price, decimal) = pyth_parser::get_price(state, price_info_object, clock);
        assert!(price > 0, E_INVALID_PRICE);

        if (decimal > oracle.decimal) {
            price = price / pow(10, ((decimal - oracle.decimal) as u8));
        } else {
            price = price * pow(10, ((oracle.decimal - decimal) as u8));
        };

        oracle.price = price;
        let ts_ms = clock::timestamp_ms(clock);
        oracle.ts_ms = ts_ms;
        oracle.epoch = tx_context::epoch(ctx);

        let (price, decimal, pyth_ts) = pyth_parser::get_ema_price(price_info_object);
        assert!(price > 0, E_INVALID_PRICE);
        assert!(ts_ms/1000 - pyth_ts < oracle.time_interval, E_ORACLE_EXPIRED);

        if (decimal > oracle.decimal) {
            price = price / pow(10, ((decimal - oracle.decimal) as u8));
        } else {
            price = price * pow(10, ((oracle.decimal - decimal) as u8));
        };

        oracle.twap_price = price;

        emit(PriceEvent {id: object::id(oracle), price, ts_ms});
    }


    public entry fun copy_manager_cap(
        _manager_cap: &ManagerCap,
        recipient: address,
        ctx: &mut TxContext
    ) {
        transfer::transfer(ManagerCap {id: object::new(ctx)}, recipient);
    }

    public fun get_oracle(
        oracle: &Oracle
    ): (u64, u64, u64, u64) {
        (oracle.price, oracle.decimal, oracle.ts_ms, oracle.epoch)
    }

    public fun get_token(
        oracle: &Oracle
    ): (String, String, TypeName, TypeName) {
        (oracle.base_token, oracle.quote_token, oracle.base_token_type, oracle.quote_token_type)
    }

    public fun get_price(
        oracle: &Oracle,
        clock: &Clock,
    ): (u64, u64) {
        let ts_ms = clock::timestamp_ms(clock);
        assert!(ts_ms - oracle.ts_ms < oracle.time_interval, E_ORACLE_EXPIRED);
        (oracle.price, oracle.decimal)
    }

    public fun get_twap_price(
        oracle: &Oracle,
        clock: &Clock,
    ): (u64, u64) {
        let ts_ms = clock::timestamp_ms(clock);
        assert!(ts_ms - oracle.ts_ms < oracle.time_interval, E_ORACLE_EXPIRED);
        (oracle.twap_price, oracle.decimal)
    }

    public entry fun update_time_interval(
        oracle: &mut Oracle,
        _manager_cap: &ManagerCap,
        time_interval: u64,
    ) {
        oracle.time_interval = time_interval;
    }

    public entry fun update_token(
        oracle: &mut Oracle,
        _manager_cap: &ManagerCap,
        quote_token: String,
        base_token: String,
    ) {
        oracle.quote_token = quote_token;
        oracle.base_token = base_token;
    }


    const E_ORACLE_EXPIRED: u64 = 1;
    const E_INVALID_PRICE: u64 = 2;
    const E_NOT_SWITCHBOARD: u64 = 3;
    const E_INVALID_SWITCHBOARD: u64 = 4;
    const E_NOT_PYTH: u64 = 5;
    const E_INVALID_PYTH: u64 = 6;

    struct PriceEvent has copy, drop { id: ID, price: u64, ts_ms: u64 }
}