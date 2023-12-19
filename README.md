# Allin Oracle

## Deploy

`sui client publish  --gas-budget 10000`

`export ORACLE_PACKAGE=0x0a55a6dfa713f83cb3be5e3ca8a8435ccdbb500d`

`sui client call --gas-budget 10000 --package $ORACLE_PACKAGE --module "unix_time" --function "new_time"`

`sui client call --gas-budget 10000 --package $ORACLE_PACKAGE --module "oracle" --function "new_oracle" --type-args  0xa1d0cdb1b41c786d53a03d30340ab05718010e04::btc::BTC --args 0x8`

`sui client call --gas-budget 10000 --package $ORACLE_PACKAGE --module "oracle" --function "new_oracle" --type-args  0xa1d0cdb1b41c786d53a03d30340ab05718010e04::eth::ETH --args 0x8`

## Usage

### PACKAGE

`0x0a55a6dfa713f83cb3be5e3ca8a8435ccdbb500d`

### Time Oracle (20s update)

1. unix_time: `0x31ce3e644e13dcb241d68bdba2783b1d6ab72a6c`
    - Key: `0xdc99399ec8f5a1888eed19fe17e945a1196df15b`

### Price Oracle (20s update)

1. BTC `0x379cf4a0b69012736feeb64302c4d6ce0a29fca7`

    - Token: `0xa1d0cdb1b41c786d53a03d30340ab05718010e04::btc::BTC`
    - Key: `0xd48b60fed34e7ab93f5a65ef5b6805e453e4d40e`
    - Data Source: https://api.binance.com/api/v3/ticker/price?symbol=BTCBUSD

2. ETH `0x14af45e8938c39e845ca189fa898f1e569ea2ced`

    - Token: `0xa1d0cdb1b41c786d53a03d30340ab05718010e04::eth::ETH`
    - Key: `0xca4037ffae6006e2e7ce1db1ac74b1d25e5d0b3a`
    - Data Source: https://api.binance.com/api/v3/ticker/price?symbol=ETHBUSD

3. SUI `0xb2a281264d928622999103afa27fceead0cb2b86`
    - Token: `0xa1d0cdb1b41c786d53a03d30340ab05718010e04::sui::SUI`
    - Key: `0x69e764b55e7dfcf5604da8cf5571e5e8501f294f`

<!-- ## Supra Oracle
https://supraoracles.com

`sui client call --gas-budget 10000 --package $PACKAGE --module "supra" --function "retrieve_price" --args 0xc40820e20346809f11f0bd04e954792f897a84d0 btc_usdt` -->

### Testnet (Updated)

```
    "TOKEN_PACKAGE": "0xd175cff04f1d49574efb6f138bc3b9b7313915a57b5ca04141fb1cb4f66984b2",
    "ORACLE_PACKAGE": "0x4144cc4bf374646f45927ca82482ab99920b78477bce572d10b7e49d746108c9",
    "BTC_ORACLE": "0x7517f836e6ad37b168c31efafd7c708045cb4d4de6975e4ea6033e79574d0244",
    "BTC_ORACLE_KEY": "0xe8e24e5590fd3b5f6021742a6188514e35f9e2cc6fa0d6938268955460ef14af",
    "ETH_ORACLE": "0x1749868f767680bbe409dbabb94094bc691f09d1e55958ad4dc1a718b701465f",
    "ETH_ORACLE_KEY": "0x6ec01fa9fe697ed56f1d27bada9d96e4b3da1f3e99abe18db0b7265350c6ca74",
    "SUI_ORACLE": "0x579b4006caca220b703c2e919f5b8fa26a600a349a42624577d49e8802506456",
    "SUI_ORACLE_KEY": "0xa06bb17223a82ca842735e249d99b658567196a72ad85a3a6a9ab115a36fa89b",
    "APT_ORACLE": "0x5de8d72df3fe762a2d5d0a51ce1bd6d0c1b2975c4e7414a4a2eb5c410035c66e",
    "APT_ORACLE_KEY": "0xf3e598e304e444f9827d20a0918969dc824314102c143ee67f25f1c80d54d988",
    "DOGE_ORACLE": "0xe43157e6cf9d4090245c7710e1a015cded9c376e25742b590ee9c06989826972",
    "DOGE_ORACLE_KEY": "0x7df1df5bbe3b5086a7318fceea6bee603d03b917574fff894fd6408f5956d1fb"
```
