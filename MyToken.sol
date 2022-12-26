// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Snapshot.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract MyToken is ERC20, ERC20Snapshot, Ownable {

    ERC20Snapshot ApeCoin = ERC20Snapshot(0x4d224452801ACEd8B2F0aebE155379bb5D594381);
    ERC721 collection = ERC721(0x0A8D311B99DdAA9EBb45FD606Eb0A1533004f26b);

    mapping (address => bool) claimed;
    mapping (uint256 => bool) NFTclaimed;
    uint256 airdropClaims;

    // NFT tutanlar için aldığımız off-chain snapshot'un whitelist'i
    bytes32 public merkleRoot = 0x235a431d30b7cc19b656d1ef14a6c5a257aab377a5854800c2d5446a1d3beb33;

    constructor() ERC20("MyToken", "MTK") {}

    // ***** TOKEN HOLDERLARINA AIRDROP ***** //

    // Snapshot ile
    function airdropClaimSnapshot() public {
        require(!claimed[_msgSender()], "You have already claimed!");
        require(airdropClaims < 100000000 ether, "All airdrop tokens have been claimed!");

        claimed[_msgSender()] = true;   // Adresi claim etti olarak kaydedelim.

        // 1 numaralı snapshot'da be bu adresin ne kadar ApeCoin'i olduğu bilgisini alalım.
        uint256 holdingAmount = ApeCoin.balanceOfAt(_msgSender(), 1);

        uint256 airdropAmount = holdingAmount * 2.7 ether; // Airdrop hakkını hesaplıyoruz

        // Eğer bu adrese vereceğimiz miktar toplam aiordrop miktarı olan 100 milyonu geçiyorsa 
        // 100 milyona kadar olan hakkını verip kalanını veremiyoruz, yoksa 100 milyon airdrop hakkı geçilmiş olur.
        if (airdropAmount + airdropClaims > 100000000 ether){
            uint256 extraAmount = 100000000 ether - airdropAmount + airdropClaims;  // Fazlalık miktarı alalım
            airdropAmount -= extraAmount;   // Fazlalığı hak edilen airdroptan çıkaralım

            airdropClaims += airdropAmount; // Mintlenecek airdrop miktarını kaydedelim
            _mint(_msgSender(), airdropAmount);  // Hak edilen airdrop miktarını mintleyelim.

            // Pre-mint ile airdrop tokenlarını Owner tutuyorsa _mint fonksiyonu yerine:
            // transferFrom(owner(), _msgSender(), airdropAmount);
        }
        // Eğer airdrop miktarı 100 milyonu geçmiyorsa direkt olarak mintle
        else {
            airdropClaims += airdropAmount; // Mintlenecek airdrop miktarını kaydedelim
            _mint(_msgSender(), airdropAmount); // Hak edilen airdrop miktarını mintleyelim.

            // Pre-mint ile airdrop tokenlarını Owner tutuyorsa _mint fonksiyonu yerine:
            // transferFrom(owner(), _msgSender(), airdropAmount);
        }        
    }

    // Snapshot olmadan
    function airdropClaim() public {
        require(!claimed[_msgSender()], "You have already claimed!");
        require(airdropClaims < 100000000 ether, "All airdrop tokens have been claimed!");

        claimed[_msgSender()] = true;   // Adresi claim etti olarak kaydedelim.

        // Claim eden kişinin kaç adet ApeCoin'i olduğu bilgisini alıyoruz.
        uint256 holdingAmount = ApeCoin.balanceOf(_msgSender());

        uint256 airdropAmount = holdingAmount * 2.7 ether; // Airdrop hakkını hesaplıyoruz

        // Eğer bu adrese vereceğimiz miktar toplam aiordrop miktarı olan 100 milyonu geçiyorsa 
        // 100 milyona kadar olan hakkını verip kalanını veremiyoruz, yoksa 100 milyon airdrop hakkı geçilmiş olur.
        if (airdropAmount + airdropClaims > 100000000 ether){
            uint256 extraAmount = 100000000 ether - airdropAmount + airdropClaims;  // Fazlalık miktarı alalım
            airdropAmount -= extraAmount;   // Fazlalığı hak edilen airdroptan çıkaralım

            airdropClaims += airdropAmount; // Mintlenecek airdrop miktarını kaydedelim
            _mint(_msgSender(), airdropAmount);  // Hak edilen airdrop miktarını mintleyelim.

            // Pre-mint ile airdrop tokenlarını Owner tutuyorsa _mint fonksiyonu yerine:
            // transferFrom(owner(), _msgSender(), airdropAmount);
        }
        // Eğer airdrop miktarı 100 milyonu geçmiyorsa direkt olarak mintle
        else {
            airdropClaims += airdropAmount; // Mintlenecek airdrop miktarını kaydedelim
            _mint(_msgSender(), airdropAmount); // Hak edilen airdrop miktarını mintleyelim.

            // Pre-mint ile airdrop tokenlarını Owner tutuyorsa _mint fonksiyonu yerine:
            // transferFrom(owner(), _msgSender(), airdropAmount);
        }        
    }

    // ***** NFT HOLDERLARINA AIRDROP ***** //

    // Contratı yayınladıktan sonra root'umuzu güncellemek için gerekli fonksiyonumuz
    function setMerkleRoot(bytes32 _newRoot) external onlyOwner {
        merkleRoot = _newRoot;
    }

    // Merkle proof'u kullanarak etkileşime giren adresin listede olup olmadığının kontrolünü yapan fonksiyonumuz
    function merkleCheck(bytes32[] calldata _merkleProof) private view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        return MerkleProof.verify(_merkleProof, merkleRoot, leaf);
    }

    function NFTwhitelistMint(bytes32[] calldata _merkleProof) public {
        require(merkleCheck(_merkleProof), "You are not in the whitelist!");
        require(!claimed[_msgSender()], "You have already minted!");
        claimed[_msgSender()] = true;

        _mint(_msgSender(), 10000 ether);
    }

    function NFTmint(uint256 tokenID) public {
        require(!NFTclaimed[tokenID], "You have already claimed!");
        NFTclaimed[tokenID] = true;   // NFT'yi claim etti olarak kaydedelim.

        require(_msgSender() == collection.ownerOf(tokenID), "You are not the owner of this NFT!");

        _mint(_msgSender(), 10000 ether);
    }


    function snapshot() public onlyOwner {
        _snapshot();
    }

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }

    // The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(address from, address to, uint256 amount)
        internal
        override(ERC20, ERC20Snapshot)
    {
        super._beforeTokenTransfer(from, to, amount);
    }


}
