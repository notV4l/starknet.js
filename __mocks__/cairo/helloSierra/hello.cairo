use array::ArrayTrait;
use array::SpanTrait;
use option::OptionTrait;
use traits::TryInto;
use serde::Serde;

// bet part
use starknet::ContractAddress;
use starknet::get_caller_address;
use starknet::StorageAccess;
use starknet::storage_access;
use starknet::StorageBaseAddress;
use starknet::SyscallResult;
use starknet::storage_read_syscall;
use starknet::storage_write_syscall;
use starknet::storage_address_from_base_and_offset;
use starknet::storage_base_address_from_felt252;

use traits::Into;
use starknet::storage_access::StorageAddressSerde;
use box::BoxTrait;
// end bet part

#[derive(Drop)]
struct Foo {
    val: felt252
}

impl FooSerde of Serde::<Foo> {
    fn serialize(ref serialized: Array<felt252>, input: Foo) {
        Serde::<felt252>::serialize(ref serialized, input.val);
    }

    fn deserialize(ref serialized: Span<felt252>) -> Option<Foo> {
        let val: felt252 = *serialized.pop_front()?;
        Option::Some(Foo { val } )
    }
}

// Complex Structs
#[derive(Copy, Drop, Serde)]
struct UserData {
    address: ContractAddress,
    is_claimed: bool,
}

#[derive(Copy, Drop, Serde)]
struct Bet {
    name: felt252,
    description: felt252,
    expire_date: u64,
    creation_time: u64,
    creator: ContractAddress,
    is_cancelled: bool,
    is_voted: bool,
    bettor: UserData,
    counter_bettor: UserData,
    winner: bool,
    pool: u256,
    amount: u256,
}

impl UserDataStorageAccess of StorageAccess::<UserData> {
    fn read(address_domain: u32, base: StorageBaseAddress) -> SyscallResult::<UserData> {
        Result::Ok( 
            UserData {
                address: storage_read_syscall(
                    address_domain, storage_address_from_base_and_offset(base, 0_u8)
                )?.try_into().unwrap(),
                is_claimed: storage_read_syscall(
                    address_domain, storage_address_from_base_and_offset(base, 1_u8)
                )? != 0,
            }
        )
    }

    fn write(address_domain: u32, base: StorageBaseAddress, value: UserData) -> SyscallResult::<()> {
        storage_write_syscall(
            address_domain, storage_address_from_base_and_offset(base, 0_u8), value.address.into()
        )?;
        storage_write_syscall(
            address_domain,
            storage_address_from_base_and_offset(base, 1_u8),
            if value.is_claimed {
                1
            } else {
                0
            }
        )
    }
}

impl UserDataSerde of serde::Serde::<UserData> {
    fn serialize(ref serialized: Array::<felt252>, input: UserData) {
        serde::Serde::serialize(ref serialized, input.address);
        serde::Serde::serialize(ref serialized, input.is_claimed);
    }
    fn deserialize(ref serialized: Span::<felt252>) -> Option::<UserData> {
        Option::Some(
            UserData {
                address: Serde::deserialize(ref serialized)?,
                is_claimed: Serde::deserialize(ref serialized)?
            }
        )
    }
}

impl BetStorageAccess of StorageAccess::<Bet> {
    fn read(address_domain: u32, base: StorageBaseAddress) -> SyscallResult::<Bet> {
        
        let name_base = storage_base_address_from_felt252(storage_address_from_base_and_offset(base, 0_u8).into());
        let name = StorageAccess::read(address_domain, name_base)?;

        let description_base = storage_base_address_from_felt252(storage_address_from_base_and_offset(base, 1_u8).into());
        let description = StorageAccess::read(address_domain, description_base)?;

        let expire_date_base = storage_base_address_from_felt252(storage_address_from_base_and_offset(base, 2_u8).into());
        let expire_date = StorageAccess::read(address_domain, expire_date_base)?;

        let creation_time_base = storage_base_address_from_felt252(storage_address_from_base_and_offset(base, 3_u8).into());
        let creation_time = StorageAccess::read(address_domain, creation_time_base)?;

        let creator_base = storage_base_address_from_felt252(storage_address_from_base_and_offset(base, 4_u8).into());
        let creator = StorageAccess::read(address_domain, creator_base)?;

        let is_cancelled_base = storage_base_address_from_felt252(storage_address_from_base_and_offset(base, 5_u8).into());
        let is_cancelled = StorageAccess::read(address_domain, is_cancelled_base)? != 0;

        let is_voted_base = storage_base_address_from_felt252(storage_address_from_base_and_offset(base, 6_u8).into());
        let is_voted = StorageAccess::read(address_domain, is_voted_base)? != 0;

        let bettor_base = storage_base_address_from_felt252(storage_address_from_base_and_offset(base, 7_u8).into());
        let bettor = StorageAccess::read(address_domain, bettor_base)?;

        let counter_bettor_base = storage_base_address_from_felt252(storage_address_from_base_and_offset(base, 9_u8).into());
        let counter_bettor = StorageAccess::read(address_domain, counter_bettor_base)?;

        let winner_base = storage_base_address_from_felt252(storage_address_from_base_and_offset(base, 11_u8).into());
        let winner = StorageAccess::read(address_domain, winner_base)? != 0;

        let pool_base = storage_base_address_from_felt252(storage_address_from_base_and_offset(base, 12_u8).into());
        let pool =  u256 {
            low: StorageAccess::<u128>::read(address_domain, pool_base)?,
            high: storage_read_syscall(
            address_domain, storage_address_from_base_and_offset(pool_base, 1_u8)
            )?.try_into().expect('StorageAccessU256 - non u256')
        };

        let amount_base = storage_base_address_from_felt252(storage_address_from_base_and_offset(base, 14_u8).into());
        let amount =  u256 {
            low: StorageAccess::<u128>::read(address_domain, amount_base)?,
            high: storage_read_syscall(
            address_domain, storage_address_from_base_and_offset(amount_base, 1_u8)
            )?.try_into().expect('StorageAccessU256 - non u256')
        };

        Result::Ok( Bet {name, description, expire_date, creation_time, creator, is_cancelled, is_voted, bettor, counter_bettor, winner, pool, amount})
    }

    fn write(address_domain: u32, base: StorageBaseAddress, value: Bet) -> SyscallResult::<()> {
        let name_base = storage_base_address_from_felt252(storage_address_from_base_and_offset(base, 0_u8).into());
        StorageAccess::write(address_domain, name_base, value.name)?;

        let description_base = storage_base_address_from_felt252(storage_address_from_base_and_offset(base, 1_u8).into());
        StorageAccess::write(address_domain, description_base, value.description)?;

        let expire_date_base = storage_base_address_from_felt252(storage_address_from_base_and_offset(base, 2_u8).into());
        StorageAccess::write(address_domain, expire_date_base, value.expire_date)?;

        let creation_time_base = storage_base_address_from_felt252(storage_address_from_base_and_offset(base, 3_u8).into());
        StorageAccess::write(address_domain, creation_time_base, value.creation_time)?;

        let creator_base = storage_base_address_from_felt252(storage_address_from_base_and_offset(base, 4_u8).into());
        StorageAccess::write(address_domain, creator_base, value.creator)?;

        let is_cancelled_base = storage_base_address_from_felt252(storage_address_from_base_and_offset(base, 5_u8).into());
        StorageAccess::write(address_domain, is_cancelled_base, if value.is_cancelled {
            1
        } else {
            0
        });

        let is_voted_base = storage_base_address_from_felt252(storage_address_from_base_and_offset(base, 6_u8).into());
        StorageAccess::write(address_domain, is_voted_base, if value.is_voted {
            1
        } else {
            0
        });

        let bettor_base = storage_base_address_from_felt252(storage_address_from_base_and_offset(base, 7_u8).into());
        StorageAccess::write(address_domain, bettor_base, value.bettor)?;

        let counter_bettor_base = storage_base_address_from_felt252(storage_address_from_base_and_offset(base, 9_u8).into());
        StorageAccess::write(address_domain, counter_bettor_base, value.counter_bettor)?;

        let winner_base = storage_base_address_from_felt252(storage_address_from_base_and_offset(base, 11_u8).into());
        StorageAccess::write(address_domain, winner_base, if value.winner {
            1
        } else {
            0
        });
            
        let pool_base = storage_base_address_from_felt252(
            storage_address_from_base_and_offset(base, 12_u8).into()
        );
        StorageAccess::write(address_domain, pool_base, value.pool.low)?;
        storage_write_syscall(
            address_domain, storage_address_from_base_and_offset(pool_base, 1_u8), value.pool.high.into()
        )?;

        let amount_base = storage_base_address_from_felt252(
            storage_address_from_base_and_offset(base, 14_u8).into()
        );
        StorageAccess::write(address_domain, amount_base, value.amount.low);
        storage_write_syscall(
            address_domain, storage_address_from_base_and_offset(amount_base, 1_u8), value.amount.high.into()
        )
    }
}

impl BetSerde of serde::Serde::<Bet> {
    fn serialize(ref serialized: Array::<felt252>, input: Bet) {
        serde::Serde::serialize(ref serialized, input.name);
        serde::Serde::serialize(ref serialized, input.description);
        serde::Serde::serialize(ref serialized, input.expire_date);
        serde::Serde::serialize(ref serialized, input.creation_time);
        serde::Serde::serialize(ref serialized, input.creator);
        serde::Serde::serialize(ref serialized, input.is_cancelled);
        serde::Serde::serialize(ref serialized, input.is_voted);
        serde::Serde::serialize(ref serialized, input.bettor.address);
        serde::Serde::serialize(ref serialized, input.bettor.is_claimed);
        serde::Serde::serialize(ref serialized, input.counter_bettor.address);
        serde::Serde::serialize(ref serialized, input.counter_bettor.is_claimed);
        serde::Serde::serialize(ref serialized, input.winner);
        serde::Serde::serialize(ref serialized, input.pool.low);
        serde::Serde::serialize(ref serialized, input.pool.high);
        serde::Serde::serialize(ref serialized, input.amount.low);
        serde::Serde::serialize(ref serialized, input.amount.high);
    }
    fn deserialize(ref serialized: Span::<felt252>) -> Option::<Bet> {
        Option::Some(
            Bet {
                name: Serde::deserialize(ref serialized)?, 
                description: Serde::deserialize(ref serialized)?,  
                expire_date: Serde::deserialize(ref serialized)?, 
                creation_time: Serde::deserialize(ref serialized)?, 
                creator: Serde::deserialize(ref serialized)?, 
                is_cancelled: Serde::deserialize(ref serialized)?, 
                is_voted: Serde::deserialize(ref serialized)?, 
                bettor: UserData {
                    address: Serde::deserialize(ref serialized)?,
                    is_claimed: Serde::deserialize(ref serialized)?,
                },
                counter_bettor: UserData {
                    address: Serde::deserialize(ref serialized)?,
                    is_claimed: Serde::deserialize(ref serialized)?,
                },
                winner: Serde::deserialize(ref serialized)?,
                pool: u256 {
                    low: Serde::deserialize(ref serialized)?,
                    high: Serde::deserialize(ref serialized)?,
                },
                amount: u256 {
                    low: Serde::deserialize(ref serialized)?,
                    high: Serde::deserialize(ref serialized)?,
                }
            }
        )
    }
}

// MAIN APP
#[contract]
mod HelloStarknet {
    //  libs
    use starknet::ContractAddress;
    use super::Foo;
    use starknet::get_caller_address;

    //bet
    use super::Bet;
    use super::UserData;
    
    struct Storage {
        balance: felt252,
        balance_u8: u8,
        status: bool,
        ca: ContractAddress,
        testbet: Bet,
        user: UserData,
    }

    // Felt252 test.
    #[external]
    fn increase_balance(amount: felt252) {
        balance::write(balance::read() + amount);
    }

    #[view]
    fn get_balance() -> felt252 {
        balance::read()
    }

    // Bool Test
    #[external]
    fn set_status(new_status: bool) {
        status::write(new_status);
    }

    #[view]
    fn get_status() -> bool {
        status::read()
    }

    // ContractAddress
    #[external]
    fn set_ca(address: ContractAddress) {
        ca::write(address);
    }

    #[view]
    fn get_ca() -> ContractAddress {
        ca::read()
    }

    // u8 Test.
    #[external]
    fn increase_balance_u8(amount: u8) {
        balance_u8::write(balance_u8::read() + amount);
    }

    #[view]
    fn get_balance_u8() -> u8 {
        balance_u8::read()
    }

    #[view]
    fn test_u16(p1: u16) -> u16 {
        p1 + 1_u16
    }

    #[view]
    fn test_u32(p1: u32) -> u32 {
        p1 + 1_u32
    }
    
    #[view]
    fn test_u64(p1: u64) -> u64 {
        p1 + 1_u64
    }

    #[view]
    fn test_u128(p1: u128) -> u128 {
        p1 + 1_u128
    }

    #[view]
    fn test_u256(p1: u256) -> u256 {
        let to_add = u256 { low: 1_u128, high: 0_u128 };
        p1 + to_add
    }

    // echo Array
    #[view]
    fn echo_array(data: Array<u8>) -> Array<u8> {
        data
    }

    #[view]
    fn echo_array_u256(data: Array<u256>) -> Array<u256> {
        data
    }

    #[view]
    fn echo_array_bool(data: Array<bool>) -> Array<bool> {
        data
    }

    // unamed Tuple
    #[view]
    fn echo_un_tuple(a:(felt252, u16)) -> (felt252, u16) {
        a
    }

    // echo Struct
    #[view]
    fn echo_struct(tt: Foo) -> Foo {
        tt
    }

    #[external]
    fn set_bet() {
        let sender = get_caller_address();
        let user = UserData{address: sender, is_claimed: false};
        testbet::write(Bet { name: 'test', description: 'dec', expire_date: 1_u64, creation_time: 1_u64, 
            creator: sender, is_cancelled: false, is_voted: false, bettor: user, counter_bettor: user, winner: false, 
            pool: u256 {low: 10_u128, high: 0_u128}, amount: u256 {low: 1000_u128, high: 0_u128}}
        );
    }

    #[view]
    fn get_bet(test: felt252) -> Bet {
        testbet::read()
    }

    // this method is required so that ABI have UserData definition in structs
    #[view]
    fn get_user() -> UserData {
        user::read()
    }

}
