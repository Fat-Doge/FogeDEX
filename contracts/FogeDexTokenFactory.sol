pragma solidity =0.5.16;

import './interfaces/IFogeDexFactory.sol';
import './FogeDexPair.sol';

contract FogeDexTokenFactory{
    address public fogeToken;
    address[] public currentPresales;
    address[] public pastPresales;
    address[] public nonPresales;
    struct tokenInfoStruct {
        address owner;
        address token;
        address token2; //always foge
        uint256 presaleEndTime;
        uint256 presaleLimit;
        uint256 presalePerc; //% going to presale(max 40)
        uint256 stakePerc; //% going to staking
        uint256 liqPerc; //% going to liquidity
        uint256 ownerPerc; //% going to owner(max 10)
        uint256 totalDeposited;
    }
    mapping(address => tokenInfoStruct) public tokenInfo;
    uint256 public totalTokens;

    constructor() public {
        
    }

    function factoryConstructor() {
        
    }

    function createSafemoon(
        string memory name,
        string memory symbol,
        uint256 supply,
        uint taxFee,
        uint liqFee,
        bool isPresale,
        bool isDeployed,
        uint256 presaleEndTime,
        uint256 presaleLimit,
        uint presalePerc,
        uint ownerPerc,
        uint liqPerc,
        uint stakePerc,
        uint256 ownerContribution
    ) public {
        //create contract with msg.sender as the owner
        //add pertinent info to contract init
        address tokenAddress = address(new SafeMoon(
            name, symbol, supply, taxFee, liqFee
        ));

        //add contract and info to mapping
        tokenInfo[tokenAddress].owner = owner;
        tokenInfo[tokenAddress].token = tokenAddress;
        tokenInfo[tokenAddress].token1 = fogeToken;
        require(ownerPerc + presalePerc + stakePerc + liqPerc < 100, "Cannot exceed 99%");
        require(ownerPerc <= 10, "Owner % must be less than 11");
        tokenInfo[tokenAddress].ownerPerc = ownerPerc;
        tokenInfo[tokenAddress].stakePerc = stakePerc;
        tokenInfo[tokenAddress].liqPerc = liqPerc;

        //if isPresale is true
        //set presaleEndTime
        //add contract to currentPresales array
        if (isPresale) {
            tokenInfo[tokenAddress].presaleEndTime = presaleEndTime;
            tokenInfo[tokenAddress].presaleLimit = presaleLimit;
            tokenInfo[tokenAddress].presalePerc = presalePerc;
            tokenInfo[tokenAddress].totalDeposited = IERC20(tokenAddress).transferFrom(msg.sender, address(this), ownerContribution);
            currentPresales.push(tokenAddress);
        }

        //if isPresale is false
        //transfer liq from msg.sender
        //add contract to nonPresales array
        if (!isPresale) {
            require(ownerContribution > 0, "Must provide launch liquidity");
            IERC20(tokenAddress).transferFrom(msg.sender, address(this), ownerContribution);
            nonPresales.push(tokenAddress);
            //deploy liquidity

            //transfer ownership
        
            tokenInfo[tokenAddress].isDeployed = true;
        }
        
        //increase total tokens
        totalTokens = totalTokens+1;
    }

    function deployToDEX(address token, uint256 liqAmount) internal {
        uint256 tokenAmount = IERC20(token).totalSupply().mul(
            tokenInfo[tokenAddress].liqPerc
        ).div(100);
        // approve token transfer to cover all possible scenarios
        IERC20(token).approve(address(fogeDEXRouter), tokenAmount);
        IERC20(fogeToken).approve(address(fogeDEXRouter), liqAmount);
        
        // add the liquidity
        try fogeDEXRouter.addLiquidity(
            token,
            fogeToken,
            tokenAmount,
            fogeAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            address(0),
            block.timestamp
        ) {
            
        } catch(bytes memory failErr) {
            
        }   
    }

    function depositToPresale(address token, uint256 amount) public {
        //check that presale has not ended
        require(tokenInfo[token].presaleEndTime > block.timestamp, "Presale has ended");
        //transfer over token2
        IERC20(fogeToken).transferFrom(msg.sender, address(this), amount);
        //add amount to presale limit
        require(tokenInfo[tokenAddress].totalDeposited.add(amount) <= tokenInfo[tokenAddress].presaleLimit, "Exceeds presale limit");
        tokenInfo[tokenAddress].totalDeposited = tokenInfo[tokenAddress].totalDeposited.add(amount);
        //send user tokens
        uint256 tokensReceived;
        IERC20(token).transfer(msg.sender, tokensReceived);
    }

    function endPresale(address token) public  {
        //check that presale has ended
        require(tokenInfo[token].presaleEndTime < block.timestamp, "Presale has not ended");
        //send contract ended notification
        IToken(token).presaleEnded();
        //deploy to DEX
        require(!tokenInfo[tokenAddress].isDeployed, "Already deployed");
        deployToDEX(token, tokenInfo[tokenAddress].totalDeposited);
        //transfer ownership

        //remove contract from current presales
        
        //add contract to past presales
        pastPresales.push(token);
    }

    
}