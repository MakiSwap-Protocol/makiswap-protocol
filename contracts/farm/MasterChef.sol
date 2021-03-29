// SPDX-License-Identifier: MIT

pragma solidity >=0.5.16;

import 'maki-swap-lib/contracts/math/SafeMath.sol';
import 'maki-swap-lib/contracts/token/HRC20/IHRC20.sol';
import 'maki-swap-lib/contracts/token/HRC20/SafeHRC20.sol';
import 'maki-swap-lib/contracts/access/Ownable.sol';

import "./MakiToken.sol";
import "./SoyBar.sol";

// import "@nomiclabs/buidler/console.sol";

interface IMigratorChef {
    // Perform LP token migration from legacy MakiSwap.
    // Take the current LP token address and return the new LP token address.
    // Migrator should have full access to the caller's LP token.
    // Return the new LP token address.
    //
    // XXX Migrator must have allowance access to MakiSwap LP tokens.
    // MakiSwap must mint EXACTLY the same amount of Maki LP tokens or
    // else something bad will happen. Traditional MakiSwap does not
    // do that so be careful!
    function migrate(IHRC20 token) external returns (IHRC20);
}

// MasterChef is the master of Maki. She can make Maki and she is a fair lady.
//
// Note that it's ownable and the owner wields tremendous power. The ownership
// will be transferred to a governance smart contract once MAKI is sufficiently
// distributed and the community can show to govern itself.

contract MasterChef is Ownable {
    using SafeMath for uint256;
    using SafeHRC20 for IHRC20;

    // Info of each user.
    struct UserInfo {
        uint256 amount;     // How many LP tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
        //
        // We do some fancy math here. Basically, any point in time, the amount of MAKI
        // entitled to a user but is pending to be distributed is:
        //
        //   pending reward = (user.amount * pool.accMakiPerShare) - user.rewardDebt - user.taxedAmount
        //
        // Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
        //   1. The pool's `accMakiPerShare` (and `lastRewardBlock`) gets updated.
        //   2. User receives the pending reward sent to his/her address.
        //   3. User's `amount` gets updated and taxed by 'taxedAmount'.
        //   4. User's `rewardDebt` gets updated.
    }

    // Info of each pool.
    struct PoolInfo {
        IHRC20 lpToken;           // Address of LP token contract.
        uint256 allocPoint;       // How many allocation points assigned to this pool. MAKIs to distribute per block.
        uint256 taxRate;          // Rate at which the LP token deposit is taxed.
        uint256 lastRewardBlock;  // Last block number that MAKIs distribution occurs.
        uint256 accMakiPerShare; // Accumulated MAKIs per share, times 1e12. See below.
    }


    //** ADDRESSES **//

    // The MAKI TOKEN!
    MakiToken public maki;
    // The SOY TOKEN!
    SoyBar public soy;
    // Admin address, which recieves 1.5 MAKI per block (mutable by admin)
    address public admin;
    // Treasury address, which recieves 1.5 MAKI per block (mutable by admin and dev)
    address public treasury;
    // The migrator contract. It has a lot of power. Can only be set through governance (owner).
    IMigratorChef public migrator;


    // ** GLOBAL VARIABLES ** //

    // MAKI tokens created per block.
    uint256 public makiPerBlock;
    // Bonus muliplier for early maki makers.
    uint256 public BONUS_MULTIPLIER = 1;
    // The block number when MAKI mining starts.
    uint256 public startBlock;
    // Total allocation points. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint = 0;
    

    // ** POOL VARIABLES ** //

    // Info of each pool.
    PoolInfo[] public poolInfo;
    // Info of each user that stakes LP tokens.
    mapping (uint256 => mapping (address => UserInfo)) public userInfo;

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);

    constructor(
        MakiToken _maki,
        SoyBar _soy,
        address _admin,
        address _treasury,
        uint256 _makiPerBlock,
        uint256 _startBlock
    ) public {
        maki = _maki;
        soy = _soy;
        admin = _admin;
        treasury = _treasury;
        makiPerBlock = _makiPerBlock;
        startBlock = _startBlock;

        // staking pool
        poolInfo.push(PoolInfo({
            lpToken: _maki,
            allocPoint: 1000,
            taxRate: 0,
            lastRewardBlock: startBlock,
            accMakiPerShare: 0
        }));

        totalAllocPoint = 1000;

    }

    function updateMultiplier(uint256 multiplierNumber) public onlyOwner {
        BONUS_MULTIPLIER = multiplierNumber;
    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    // VALIDATION -- ELIMINATES POOL DUPLICATION RISK -- NONE
    function checkPoolDuplicate(IHRC20 _token) public view {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            require(poolInfo[pid].lpToken != _token, "add: existing pool?");
        }
    }

    // ADD -- NEW LP TOKEN POOL -- OWNER
    function add(uint256 _allocPoint, IHRC20 _lpToken, uint256 _taxRate, bool _withUpdate) public onlyOwner {
        if (_withUpdate) {
            massUpdatePools();
        }
        uint256 lastRewardBlock = block.number > startBlock ? block.number : startBlock;
        totalAllocPoint = totalAllocPoint.add(_allocPoint);
        poolInfo.push(PoolInfo({
            lpToken: _lpToken,
            allocPoint: _allocPoint,
            taxRate: _taxRate,
            lastRewardBlock: lastRewardBlock,
            accMakiPerShare: 0
        }));
        updateStakingPool();
    }

    // UPDATE -- ALLOCATION POINT -- OWNER
    function set(uint256 _pid, uint256 _allocPoint, bool _withUpdate) public onlyOwner {
        if (_withUpdate) {
            massUpdatePools();
        }
        uint256 prevAllocPoint = poolInfo[_pid].allocPoint;
        poolInfo[_pid].allocPoint = _allocPoint;
        if (prevAllocPoint != _allocPoint) {
            totalAllocPoint = totalAllocPoint.sub(prevAllocPoint).add(_allocPoint);
            updateStakingPool();
        }
    }

    // UPDATE -- STAKING POOL -- INTERNAL
    function updateStakingPool() internal {
        uint256 length = poolInfo.length;
        uint256 points = 0;
        for (uint256 pid = 1; pid < length; ++pid) {
            points = points.add(poolInfo[pid].allocPoint);
        }
        if (points != 0) {
            points = points.div(3);
            totalAllocPoint = totalAllocPoint.sub(poolInfo[0].allocPoint).add(points);
            poolInfo[0].allocPoint = points;
        }
    }

    // SET -- MIGRATOR CONTRACT -- OWNER
    function setMigrator(IMigratorChef _migrator) public onlyOwner {
        migrator = _migrator;
    }

    // MIGRATE -- LP TOKENS TO ANOTHER CONTRACT -- MIGRATOR
    function migrate(uint256 _pid) public {
        require(address(migrator) != address(0), "migrate: no migrator");
        PoolInfo storage pool = poolInfo[_pid];
        IHRC20 lpToken = pool.lpToken;
        uint256 bal = lpToken.balanceOf(address(this));
        lpToken.safeApprove(address(migrator), bal);
        IHRC20 newLpToken = migrator.migrate(lpToken);
        require(bal == newLpToken.balanceOf(address(this)), "migrate: bad");
        pool.lpToken = newLpToken;
    }

    // VIEW -- BONUS MULTIPLIER -- PUBLIC
    function getMultiplier(uint256 _from, uint256 _to) public view returns (uint256) {
        return _to.sub(_from).mul(BONUS_MULTIPLIER);
    }

    // VIEW -- PENDING MAKI
    function pendingMaki(uint256 _pid, address _user) external view returns (uint256) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accMakiPerShare = pool.accMakiPerShare;
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
            uint256 makiReward = multiplier.mul(makiPerBlock).mul(pool.allocPoint).div(totalAllocPoint);
            accMakiPerShare = accMakiPerShare.add(makiReward.mul(1e12).div(lpSupply));
        }
        return user.amount.mul(accMakiPerShare).div(1e12).sub(user.rewardDebt);
    }

    // UPDATE -- REWARD VARIABLES FOR ALL POOLS (HIGH GAS POSSIBLE) -- PUBLIC
    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }


    // UPDATE -- REWARD VARIABLES (POOL) -- PUBLIC
    function updatePool(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        if (block.number <= pool.lastRewardBlock) {
            return;
        }
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (lpSupply == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }
        uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
        uint256 makiReward = 
            multiplier.mul(makiPerBlock).mul(pool.allocPoint).div(totalAllocPoint);

        maki.mint(admin, makiReward.mul(15).div(130)); // 1.5 MAKI per block to admin
        maki.mint(treasury, makiReward.mul(15).div(130)); // 1.5 MAKI per block to treasury
        
        maki.mint(address(soy), makiReward);

        pool.accMakiPerShare = pool.accMakiPerShare.add(
            makiReward.mul(1e12).div(lpSupply));

        pool.lastRewardBlock = block.number;
    }

    // DEPOSIT -- LP TOKENS -- LP OWNERS
    function deposit(uint256 _pid, uint256 _amount) public {

        require (_pid != 0, 'deposit MAKI by staking');

        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        updatePool(_pid);
        uint256 taxedAmount = pool.taxRate == 0 ? 0 : _amount.div(pool.taxRate); // fix: division by 0 error

        if (user.amount > 0) { // already deposited assets
            uint256 pending = user.amount.mul(pool.accMakiPerShare).div(1e12).sub(user.rewardDebt);
            if(pending > 0) { // sends pending rewards, if applicable
                safeMakiTransfer(msg.sender, pending);
            }
        }

        if (_amount > 0) { // if adding more
            pool.lpToken.safeTransferFrom(address(msg.sender), address(this), _amount.sub(taxedAmount));
            pool.lpToken.safeTransferFrom(address(msg.sender), address(treasury), taxedAmount);

            user.amount = user.amount.add(_amount.sub(taxedAmount)); // new user.amount == untaxed amount
        }
        user.rewardDebt = user.amount.mul(pool.accMakiPerShare).div(1e12);
        emit Deposit(msg.sender, _pid, _amount.sub(taxedAmount));
    }

    // WITHDRAW -- LP TOKENS -- STAKERS
    function withdraw(uint256 _pid, uint256 _amount) public {

        require (_pid != 0, 'withdraw MAKI by unstaking');
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.amount >= _amount, "withdraw: not good");

        updatePool(_pid);
        uint256 pending = user.amount.mul(pool.accMakiPerShare).div(1e12).sub(user.rewardDebt);
        if(pending > 0) {
            safeMakiTransfer(msg.sender, pending);
        }
        if(_amount > 0) {
            user.amount = user.amount.sub(_amount);
            pool.lpToken.safeTransfer(address(msg.sender), _amount);
        }
        user.rewardDebt = user.amount.mul(pool.accMakiPerShare).div(1e12);
        emit Withdraw(msg.sender, _pid, _amount);
    }

    // STAKE -- MAKI TO MASTERCHEF -- PUBLIC MAKI HOLDERS
    function enterStaking(uint256 _amount) public {
        PoolInfo storage pool = poolInfo[0];
        UserInfo storage user = userInfo[0][msg.sender];
        updatePool(0);
        if (user.amount > 0) {
            uint256 pending = user.amount.mul(pool.accMakiPerShare).div(1e12).sub(user.rewardDebt);
            if(pending > 0) {
                safeMakiTransfer(msg.sender, pending);
            }
        }
        if(_amount > 0) {
            pool.lpToken.safeTransferFrom(address(msg.sender), address(this), _amount);
            user.amount = user.amount.add(_amount);
        }
        user.rewardDebt = user.amount.mul(pool.accMakiPerShare).div(1e12);

        soy.mint(msg.sender, _amount);
        emit Deposit(msg.sender, 0, _amount);
    }

    // WITHDRAW -- MAKI tokens from STAKING.
    function leaveStaking(uint256 _amount) public {
        PoolInfo storage pool = poolInfo[0];
        UserInfo storage user = userInfo[0][msg.sender];
        require(user.amount >= _amount, "withdraw: not good");
        updatePool(0);
        uint256 pending = user.amount.mul(pool.accMakiPerShare).div(1e12).sub(user.rewardDebt);
        if(pending > 0) {
            safeMakiTransfer(msg.sender, pending);
        }
        if(_amount > 0) {
            user.amount = user.amount.sub(_amount);
            pool.lpToken.safeTransfer(address(msg.sender), _amount);
        }
        user.rewardDebt = user.amount.mul(pool.accMakiPerShare).div(1e12);

        soy.burn(msg.sender, _amount);
        emit Withdraw(msg.sender, 0, _amount);
    }

    // TRANSFER -- TRANSFERS SOY -- INTERNAL
    function safeMakiTransfer(address _to, uint256 _amount) internal {
        soy.safeMakiTransfer(_to, _amount);
    }

    // UPDATE -- TREASURY ADDRESS -- TREASURY || ADMIN
    function newTreasury(address _treasury) public {
        require(msg.sender == treasury || msg.sender == admin, "treasury: invalid permissions");
        treasury = _treasury;
    }

    // UPDATE -- ADMIN ADDRESS -- ADMIN
    function newAdmin(address _admin) public {
        require(msg.sender == admin, "admin: le who are you?");
        admin = _admin;
    }
}
