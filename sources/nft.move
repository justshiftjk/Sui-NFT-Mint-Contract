
module mfs_nft::nft {
    use sui::tx_context::{sender};
    use std::string::{utf8, String};

    // The creator bundle: these two packages often go together.
    use sui::package;
    use sui::display;
    use sui::event;
    use sui::clock::Clock;
    use std::string;
    /// The Hero - an outstanding collection of digital art.
    public struct Hero has key, store {
        id: UID,
        name: String,
        image_url: String,
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

    /// Constant to define the start time for minting (in milliseconds).
    /// Replace this with the appropriate timestamp.
    const MINT_START_TIME: u64 = 1697664000000; // Example: 2023-10-01 00:00:00 UTC
    const WL_START_TIME: u64 = 1700000000000; // Example: 2023-10-01 00:00:00 UTC
    const PUBLIC_START_TIME: u64 = 1750000000000; // Example: 2023-10-01 00:00:00 UTC

    const PHASE_ONE_PRICE: u64 = 10;
    const PHASE_TWO_PRICE: u64 = 20;
    const PHASE_THREE_PRICE: u64 = 30;

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
    }

    /// Anyone can mint their `Hero`!
    public fun mint(clock: &Clock, name: String, image_url: String, ctx: &mut TxContext) {
        let current_time = clock.timestamp_ms();
        assert!(current_time >= MINT_START_TIME, 1001);
        let mut mint_price: u64 = 0;
        
        if (current_time > MINT_START_TIME && current_time < WL_START_TIME) {
            mint_price = PHASE_ONE_PRICE;
        } else if (current_time > WL_START_TIME && current_time < PUBLIC_START_TIME) {
            mint_price = PHASE_TWO_PRICE;
        } else if (current_time > PUBLIC_START_TIME) {
            mint_price = PHASE_THREE_PRICE;
        };

        let id = object::new(ctx);
        let nft = Hero { id, name, image_url };
        let sender = tx_context::sender(ctx);
        event::emit(MintNFTEvent {
            object_id: object::uid_to_inner(&nft.id),
            creator: sender,
            name: nft.name,
        });
        transfer::public_transfer(nft, sender);
    }
}