module mfs_nft::nft {
    use sui::sui::SUI;
    use sui::coin::{Self, Coin};
    use sui::balance::{Self, Balance};
    use sui::tx_context::{sender};
    use std::string::{utf8, String};
    // The creator bundle: these two packages often go together.
    use sui::package;
    use sui::display;
    use sui::event;
    use sui::clock::Clock;
    use std::string;
    /// The Hero - an outstanding collection of digital art.
    public struct Attributes has drop, store {
        map: 0x2::vec_map::VecMap<0x1::ascii::String, 0x1::ascii::String>,
    }
    public struct Hero has key, store {
        id: UID,
        name: String,
        image_url: String,
        description: String,
        attribute:Attributes
    }
    /// One-Time-Witness for the module.
    public struct NFT has drop {}
    public struct MintNFTEvent has copy, drop {
        // The Object ID of the NFT
        object_id: ID,
        // The creator of the NFT
        creator: address,
        // The name of the NFT
        name: string::String,
    }
    /// Capability that grants an owner the right to collect profits.
    public struct TreasuryOwnerCap has key { id: UID }
    public struct Treasury has key {
        id: UID,
        price: u64,
        balance: Balance<SUI>
    }
    /// Constant to define the start time for minting (in milliseconds).
    /// Replace this with the appropriate timestamp.
    const PHASE_ONE_TIME: u64 = 1729288800000; // Example: 2024-10-18 22:00:00 UTC
    // const PHASE_TWO_TIME: u64 = 1687664000000; 
    const PHASE_THREE_TIME: u64 = 1687664000000; 
    const PHASE_FOUR_TIME: u64 = 1687664000000; 
    const PHASE_FIVE_TIME: u64 = 1687664000000; 
    const PHASE_ONE_PRICE: u64 = 5550000000;
    const PHASE_TWO_PRICE: u64 = 7770000000;
    const PHASE_THREE_PRICE: u64 = 11100000000;

    //TREASURY ADDY
    const TREASURY_WALLET: address = @0xa7ae4f7d7297c609d5c115ec6a4b516dfe222d6e40d020a9e81ec189078d646e;

    /// In the module initializer one claims the `Publisher` object
    /// to then create a `Display`. The `Display` is initialized with
    /// a set of fields (but can be modified later) and published via
    /// the `update_version` call.
    ///
    /// Keys and values are set in the initializer but could also be
    /// set after publishing if a `Publisher` object was created.
    fun init(otw: NFT, ctx: &mut TxContext) {
        let keys = vector[
            utf8(b"name"),
            utf8(b"link"),
            utf8(b"image_url"),
            utf8(b"description"),
            utf8(b"project_url"),
            utf8(b"creator"),
        ];
        let values = vector[
            // For `name` one can use the `Hero.name` property
            utf8(b"{name}"),
            // For `link` one can build a URL using an `id` property
            utf8(b"https://sui-heroes.io/hero/{id}"),
            // For `image_url` use an IPFS template + `image_url` property.
            utf8(b"ipfs://{image_url}"),
            // Description is static for all `Hero` objects.
            utf8(b"A true Hero of the Sui ecosystem!"),
            // Project URL is usually static
            utf8(b"https://sui-heroes.io"),
            // Creator field can be any
            utf8(b"Unknown Sui Fan")
        ];
        // Claim the `Publisher` for the package!
        let publisher = package::claim(otw, ctx);
        // Get a new `Display` object for the `Hero` type.
        let mut display = display::new_with_fields<Hero>(
            &publisher, keys, values, ctx
        );
        // Commit first version of `Display` to apply changes.
        display::update_version(&mut display);
        transfer::public_transfer(publisher, sender(ctx));
        transfer::public_transfer(display, sender(ctx));
        transfer::transfer(TreasuryOwnerCap {
            id: object::new(ctx)
        }, tx_context::sender(ctx));
        transfer::share_object(Treasury {
            id: object::new(ctx),
            price: 0,
            balance: balance::zero()
        })
    }

    public fun new(arg0: 0x2::vec_map::VecMap<0x1::ascii::String, 0x1::ascii::String>) : Attributes {
        Attributes{map: arg0}
    }
    public fun from_vec(arg0: vector<0x1::ascii::String>, arg1: vector<0x1::ascii::String>) : Attributes {
        new(from_vec_to_map<0x1::ascii::String, 0x1::ascii::String>(arg0, arg1))
    }
    public fun from_vec_to_map<T0: copy + drop, T1: drop>(mut arg0: vector<T0>,mut arg1: vector<T1>) : 0x2::vec_map::VecMap<T0, T1> {
        assert!(0x1::vector::length<T0>(&arg0) == 0x1::vector::length<T1>(&arg1), 1);
        let mut v0 = 0;
        let mut v1 = 0x2::vec_map::empty<T0, T1>();
        while (v0 < 0x1::vector::length<T0>(&arg0)) {
            0x2::vec_map::insert<T0, T1>(&mut v1, 0x1::vector::pop_back<T0>(&mut arg0), 0x1::vector::pop_back<T1>(&mut arg1));
            v0 = v0 + 1;
        };
        v1
    }

    /// Anyone can mint their `Hero`!
    #[allow(lint(self_transfer))] // Suppress the self_transfer lint here
    public fun mint(shop: &mut Treasury, payment: &mut Coin<SUI>, clock: &Clock, name: String, image_url: String, ctx: &mut TxContext) {
        let current_time = clock.timestamp_ms();
        assert!(current_time >= PHASE_ONE_TIME, 1001);
        if (current_time >= PHASE_THREE_TIME && current_time < PHASE_FOUR_TIME) {
            shop.price = PHASE_ONE_PRICE;
        } else if (current_time >= PHASE_FOUR_TIME && current_time < PHASE_FIVE_TIME) {
            shop.price = PHASE_TWO_PRICE;
        } else if (current_time >= PHASE_FIVE_TIME) {
            shop.price = PHASE_THREE_PRICE;
        };

        assert!(coin::value(payment) >= shop.price, 1002);

        // Take amount = `shop.price` from Coin<SUI>
        let coin_balance = coin::balance_mut(payment);
        let mut paid = balance::split(coin_balance, shop.price);
        let profits = coin::take(&mut paid, shop.price, ctx);

        transfer::public_transfer(profits, TREASURY_WALLET);
        // Put the coin to the Treasury's balance
        balance::join(&mut shop.balance, paid);

        let id = object::new(ctx);
        let nft = Hero {
            id:id,
            name:name,
            image_url:image_url,
            description:description,
            attribute:from_vec(arg3, arg4) };
        let sender = tx_context::sender(ctx);
        event::emit(MintNFTEvent {
            object_id: object::uid_to_inner(&nft.id),
            creator: sender,
            name: nft.name,
        });
        transfer::public_transfer(nft, sender);
    }
}