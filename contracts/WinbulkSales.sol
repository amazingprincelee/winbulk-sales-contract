//SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.5.0 <0.9.0;
// ----------------------------------------------------------------------------
// WINBULK SALES UTILITIES
// https://winbulk.com
// team@winbulk.com
// -----------------------------------------
// ----------------------------------------------------------------------------
// EIP-20: ERC-20 Token Standard
// https://eips.ethereum.org/EIPS/eip-20
// -----------------------------------------
interface ERC20Interface {
    function totalSupply() external view returns (uint);
    function balanceOf(address tokenOwner) external view returns (uint balance);
    function transfer(address to, uint tokens) external returns (bool success);
    
    function allowance(address tokenOwner, address spender) external view returns (uint remaining);
    function approve(address spender, uint tokens) external returns (bool success);
    function transferFrom(address from, address to, uint tokens) external returns (bool success);
    
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}



contract WinBulk is ERC20Interface{
    string public name = "WinBulk";
    string public symbol = "WBUK";
    uint public decimals = 18;
    uint public override totalSupply;
    
    address public founder;
    
    mapping(address => uint) public balances;
    
  
    
    mapping(address => mapping(address => uint)) allowed;
    
    
    
    constructor(){
        totalSupply = 100000000000000000000000000000;
        founder = msg.sender;
        balances[founder] = totalSupply;
    }
    
    
    function balanceOf(address tokenOwner) public view override returns (uint balance){
        return balances[tokenOwner];
    }
    
    
    function transfer(address to, uint tokens) public virtual override returns(bool success){
        require(balances[msg.sender] >= tokens);
        
        balances[to] += tokens;
        balances[msg.sender] -= tokens;
        emit Transfer(msg.sender, to, tokens);
        
        return true;
    }
    
    
    function allowance(address tokenOwner, address spender) public view override returns(uint){
        return allowed[tokenOwner][spender];
    }
    
    
    function approve(address spender, uint tokens) public override returns (bool success){
        require(balances[msg.sender] >= tokens);
        require(tokens > 0);
        
        allowed[msg.sender][spender] = tokens;
        
        emit Approval(msg.sender, spender, tokens);
        return true;
    }
    
    
    function transferFrom(address from, address to, uint tokens) public virtual override returns (bool success){
         require(allowed[from][to] >= tokens);
         require(balances[from] >= tokens);
         
         balances[from] -= tokens;
         balances[to] += tokens;
         allowed[from][to] -= tokens;
         
         return true;
     }
}


contract WinBulkSale is WinBulk{
    address public admin;
    address payable public deposit;
    uint public tokenPrice = 0.00000005 ether;  // 1 ETH = 20000000 WBUK, 1 WBUK = 0.00000005
    uint public hardCap = 1000 ether;
    uint public raisedAmount; // this value will be in wei
    uint public saleStart = block.timestamp;
    uint public saleEnd = block.timestamp + 2419200; //one month
    uint public maxInvestment = 5 ether;
    uint public minInvestment = 0.1 ether;

    uint public feePercentage = 10;
    uint internal coreTeamPercentage = 5;

    //Get Top Token Holders
    uint private topHoldersLimit = 10;

    // Store TopHolders wallet
    address payable[] public investorsWallets;

    // Store Core Team wallet
    address payable[] public coreTeamWallets;

    //To tract invested amount of every investor
    mapping(address => uint) public investedAmounts;
    
    enum State { beforeStart, running, afterEnd, halted} // ICO states 
    State public icoState;
    
   constructor(address payable _deposit) {
    deposit = _deposit; 
    admin = msg.sender; 
    icoState = State.beforeStart;
    distributeTokens();
    populateCoreTeamWallets();
}

    
    modifier onlyAdmin(){
        require(msg.sender == admin);
        _;
    }
    
    
    // emergency stop
    function halt() public onlyAdmin{
        icoState = State.halted;
    }
    
    
    function resume() public onlyAdmin{
        icoState = State.running;
    }
    
    
    function changeDepositAddress(address payable newDeposit) public onlyAdmin{
        deposit = newDeposit;
    }


    function setTokenPrice(uint _newPrice) public onlyAdmin {
        tokenPrice = _newPrice;
    }

    

    function increaseMaxInvestment(uint newMaxInvestment) external onlyAdmin {
    require(newMaxInvestment > maxInvestment, "New max investment should be greater than the current max investment.");
    maxInvestment = newMaxInvestment;
}

function decreaseMaxInvestment(uint newMaxInvestment) external onlyAdmin {
    require(newMaxInvestment < maxInvestment, "New max investment should be less than the current max investment.");
    maxInvestment = newMaxInvestment;
}

function increaseMinInvestment(uint newMinInvestment) external onlyAdmin {
    require(newMinInvestment > minInvestment, "New min investment should be greater than the current min investment.");
    minInvestment = newMinInvestment;
}

function decreaseMinInvestment(uint newMinInvestment) external onlyAdmin {
    require(newMinInvestment < minInvestment, "New min investment should be less than the current min investment.");
    minInvestment = newMinInvestment;
}


 function updateCoreTeamWallets(address payable _address) public {
    coreTeamWallets.push(_address);
}

function removeCoreTeamWallets(address payable wallet) public onlyAdmin {
    for (uint i = 0; i < coreTeamWallets.length; i++) {
        if (coreTeamWallets[i] == wallet) {
            // Move the last element to the current index
            coreTeamWallets[i] = coreTeamWallets[coreTeamWallets.length - 1];
            // Remove the last element
            coreTeamWallets.pop();
            break;
        }
    }
}


//Populate coreTeamWallets Array with Core Team wallet addresses

function populateCoreTeamWallets() internal {
    coreTeamWallets = new address payable[](3);  // Initialize the array with a size of 3
    coreTeamWallets[0] = payable(address(uint160(0xe025bB70A3CCb5d131120d52F0f58fB6e31fec31)));
    coreTeamWallets[1] = payable(address(uint160(0x246cc531a16103Cd883E1179ae880323D28b31C0)));
    coreTeamWallets[2] = payable(address(uint160(0xA25D29Abe744090B0bc618093c05BCB3D1A5Ab0C)));
    coreTeamWallets[2] = payable(address(uint160(0x01062b72375B5bbbC70e318B9B2501ba60a45B08)));
}



function distributeTokens() internal onlyAdmin {
    require(icoState == State.beforeStart, "Tokens can only be distributed before the sale starts");

    uint totalTokens = balances[founder];
    uint tokensToDistribute = totalTokens * 50 / 100; // 50% of total tokens to be distributed

    // Calculate the amount of tokens to send to each wallet based on the given percentages
    uint marketing = tokensToDistribute * 10 / 100; // 10% to 0x3ba994AFfda46D497D3ebf482210D12A7AB3929d
    uint team = tokensToDistribute * 15 / 100; // 15% to 0xe8E433e6d67126F91255b198d89e635227fB8511
    uint communityReward = tokensToDistribute * 5 / 100;  // 5% to 0xCD86A7602e63bd9761e6E4Fb1E4Ec5D2546E5413
    uint reserve = tokensToDistribute * 20 / 100; // 20% to 0x65a626BeD83cbf26fAb002CB2fBbEeBC4A995876

    // Deduct the distributed tokens from the founder's balance
    balances[founder] -= tokensToDistribute;

    // Transfer tokens to each wallet
    transfer(0x3ba994AFfda46D497D3ebf482210D12A7AB3929d, marketing);
    transfer(0xe8E433e6d67126F91255b198d89e635227fB8511, team);
    transfer(0xCD86A7602e63bd9761e6E4Fb1E4Ec5D2546E5413, communityReward);
    transfer(0x65a626BeD83cbf26fAb002CB2fBbEeBC4A995876, reserve);
}


    
    
    function getCurrentState() public view returns(State){
        if(icoState == State.halted){
            return State.halted;
        }else if(block.timestamp < saleStart){
            return State.beforeStart;
        }else if(block.timestamp >= saleStart && block.timestamp <= saleEnd){
            return State.running;
        }else{
            return State.afterEnd;
        }
    }


    event Invest(address investor, uint value, uint tokens);
    
    
    // function called when sending eth to the contract
   

function invest() payable public returns (bool) {
    icoState = getCurrentState();
    require(icoState == State.running);
    require(msg.value >= minInvestment && msg.value <= maxInvestment);
    require(raisedAmount + msg.value <= hardCap);
    // Check if the total invested amount doesn't exceed the maximum limit for the wallet
    require(investedAmounts[msg.sender] + msg.value <= maxInvestment, "Maximum investment limit exceeded for this wallet.");

    // Calculate the fee amount
    uint feeAmount = (msg.value * feePercentage) / 100;
    uint teamFeeAmount = (msg.value * coreTeamPercentage) / 100;
    // Deduct the fee from the invested amount
    uint investedAmount = msg.value - (feeAmount + teamFeeAmount);

    raisedAmount += investedAmount;
    uint tokens = investedAmount / tokenPrice;

    // Deduct 5% from the investment and distribute it equally to the top holders
    uint share = teamFeeAmount / coreTeamWallets.length;
    for (uint i = 0; i < coreTeamWallets.length; i++) {
        address payable wallet = coreTeamWallets[i];
        wallet.transfer(share);
    }

    balances[msg.sender] += tokens;
    balances[founder] -= tokens;
    deposit.transfer(investedAmount);

    emit Invest(msg.sender, investedAmount, tokens);

    investorsWallets.push(payable(msg.sender));
    

    // Update the invested amount for the wallet
    investedAmounts[msg.sender] += investedAmount;

    // Distribute the fee equally to wallets within the topHoldersLimit
    uint feePerWallet = 0;
    uint totalWallets = investorsWallets.length;

    if (totalWallets > topHoldersLimit) {
        totalWallets = topHoldersLimit;
    }

    if (totalWallets > 0) {
        feePerWallet = feeAmount / totalWallets;
    }

    for (uint i = 0; i < totalWallets; i++) {
        address payable wallet = investorsWallets[i];
        wallet.transfer(feePerWallet);
    }

    return true;
}




   
   // this function is called automatically when someone sends ETH to the contract's address
   receive () payable external{
        invest();
    }


    

function getTopTokenHolders() public view returns (address[] memory) {
    address[] memory topHolders = new address[](topHoldersLimit);
    uint[] memory balancesTemp = new uint[](topHoldersLimit);

    // Initialize the temporary balances array with the balances of the first topHoldersLimit token holders
    for (uint i = 0; i < topHoldersLimit; i++) {
        topHolders[i] = address(0);
        balancesTemp[i] = 0;
    }

    // Iterate through all token holders and update the top holders array
    for (uint i = 0; i < investorsWallets.length; i++) {
        address holder = investorsWallets[i];
        uint balance = balanceOf(holder);

        // Check if the current holder has a higher balance than the smallest balance in the top holders array
        if (balance > balancesTemp[topHoldersLimit - 1]) {
            // Replace the holder with the smallest balance in the top holders array
            topHolders[topHoldersLimit - 1] = holder;
            balancesTemp[topHoldersLimit - 1] = balance;

            // Sort the top holders array in descending order based on balances
            for (uint j = topHoldersLimit - 1; j > 0; j--) {
                if (balancesTemp[j] > balancesTemp[j - 1]) {
                    // Swap the holder and balance
                    (topHolders[j], topHolders[j - 1]) = (topHolders[j - 1], topHolders[j]);
                    (balancesTemp[j], balancesTemp[j - 1]) = (balancesTemp[j - 1], balancesTemp[j]);
                } else {
                    // If the balance is not larger than the previous holder's balance, the array is already sorted
                    break;
                }
            }
        }
    }

    return topHolders;
}

function setTopHoldersLimit(uint newLimit) onlyAdmin external {
    require(newLimit > 0, "Limit must be greater than zero");
    topHoldersLimit = newLimit;
}

function getTopHoldersLimit() public onlyAdmin view returns (uint) {
    return topHoldersLimit;
}

  
    
    // burning unsold tokens
    function burn() public onlyAdmin returns(bool){
        icoState = getCurrentState();
        require(icoState == State.afterEnd);
        balances[founder] = 0;
        return true;
        
    }
    
    
    function transfer(address to, uint tokens) public override returns (bool success){
        // calling the transfer function of the base contract
        super.transfer(to, tokens);  // same as WinBulk.transfer(to, tokens);
        return true;
    }
    
    
    function transferFrom(address from, address to, uint tokens) public override returns (bool success){   
        WinBulk.transferFrom(from, to, tokens);  // same as super.transferFrom(to, tokens);
        return true;
     
    }
}
