pragma solidity ^0.8.20;

contract RockPaperScissors {
    enum Move { None, Rock, Paper, Scissors }
    enum GameState { WaitingForPlayer2, Committing, Revealing, Finished }

    struct Game {
        address player1;
        address player2;
        uint256 bet;
        bytes32 p1Commit;
        bytes32 p2Commit;
        Move p1Move;
        Move p2Move;
        GameState state;
        uint256 deadline;
        bool p1Revealed;
        bool p2Revealed;
    }

    uint256 public constant REVEAL_TIMEOUT = 2 minutes;
    uint256 public nextGameId;

    mapping(uint256 => Game) public games;
    mapping(address => uint256) public balances;

    event GameCreated(uint256 indexed gameId, address indexed player1, uint256 bet);
    event GameJoined(uint256 indexed gameId, address indexed player2);
    event MoveCommitted(uint256 indexed gameId, address indexed player);
    event MoveRevealed(uint256 indexed gameId, address indexed player, Move move);
    event GameResolved(uint256 indexed gameId, address winner, uint256 amount);
    event GameCanceled(uint256 indexed gameId);
    event Withdraw(address indexed player, uint256 amount);

    modifier onlyPlayers(uint256 gameId) {
        Game storage g = games[gameId];
        require(msg.sender == g.player1 || msg.sender == g.player2, "Not a player");
        _;
    }

    modifier inState(uint256 gameId, GameState expected) {
        require(games[gameId].state == expected, "Wrong state");
        _;
    }

    function createGame(address opponent) external payable returns (uint256 gameId) {
        require(msg.value > 0, "Bet must be > 0");
        require(opponent != address(0) && opponent != msg.sender, "Invalid opponent");

        gameId = nextGameId++;
        Game storage g = games[gameId];
        g.player1 = msg.sender;
        g.player2 = opponent;
        g.bet = msg.value;
        g.state = GameState.WaitingForPlayer2;

        emit GameCreated(gameId, msg.sender, msg.value);
    }

    function joinGame(uint256 gameId)
        external
        payable
        inState(gameId, GameState.WaitingForPlayer2)
    {
        Game storage g = games[gameId];
        require(msg.sender == g.player2, "Not invited");
        require(msg.value == g.bet, "Must match bet");

        g.state = GameState.Committing;

        emit GameJoined(gameId, msg.sender);
    }

    function commitMove(uint256 gameId, bytes32 commitment)
        external
        onlyPlayers(gameId)
        inState(gameId, GameState.Committing)
    {
        Game storage g = games[gameId];

        if (msg.sender == g.player1) {
            require(g.p1Commit == bytes32(0), "Already committed");
            g.p1Commit = commitment;
        } else {
            require(g.p2Commit == bytes32(0), "Already committed");
            g.p2Commit = commitment;
        }

        if (g.p1Commit != bytes32(0) && g.p2Commit != bytes32(0)) {
            g.state = GameState.Revealing;
            g.deadline = block.timestamp + REVEAL_TIMEOUT;
        }

        emit MoveCommitted(gameId, msg.sender);
    }

    function revealMove(uint256 gameId, Move move, bytes32 salt)
        external
        onlyPlayers(gameId)
        inState(gameId, GameState.Revealing)
    {
        require(
            move == Move.Rock || move == Move.Paper || move == Move.Scissors,
            "Invalid move"
        );

        Game storage g = games[gameId];
        bytes32 expected = keccak256(abi.encodePacked(move, salt));

        if (msg.sender == g.player1) {
            require(!g.p1Revealed, "Already revealed");
            require(expected == g.p1Commit, "Commit mismatch");
            g.p1Move = move;
            g.p1Revealed = true;
        } else {
            require(!g.p2Revealed, "Already revealed");
            require(expected == g.p2Commit, "Commit mismatch");
            g.p2Move = move;
            g.p2Revealed = true;
        }

        emit MoveRevealed(gameId, msg.sender, move);

        if (g.p1Revealed && g.p2Revealed) {
            _resolve(gameId);
        }
    }

    function claimTimeout(uint256 gameId)
        external
        onlyPlayers(gameId)
        inState(gameId, GameState.Revealing)
    {
        Game storage g = games[gameId];
        require(block.timestamp >= g.deadline, "Too early");

        address winner;

        if (g.p1Revealed && !g.p2Revealed) winner = g.player1;
        else if (g.p2Revealed && !g.p1Revealed) winner = g.player2;
        else {
            // Neither revealed → refund both
            balances[g.player1] += g.bet;
            balances[g.player2] += g.bet;
            g.state = GameState.Finished;
            emit GameCanceled(gameId);
            return;
        }

        balances[winner] += 2 * g.bet;
        g.state = GameState.Finished;
        emit GameResolved(gameId, winner, 2 * g.bet);
    }

    function withdraw() external {
        uint256 amount = balances[msg.sender];
        require(amount > 0, "Nothing to withdraw");

        balances[msg.sender] = 0;
        (bool ok, ) = msg.sender.call{value: amount}("");
        require(ok, "Withdraw failed");

        emit Withdraw(msg.sender, amount);
    }

    function _resolve(uint256 gameId) internal {
        Game storage g = games[gameId];

        address winner;

        if (g.p1Move == g.p2Move) {
            // Tie → refund both
            balances[g.player1] += g.bet;
            balances[g.player2] += g.bet;
            emit GameCanceled(gameId);
        } else if (
            (g.p1Move == Move.Rock     && g.p2Move == Move.Scissors) ||
            (g.p1Move == Move.Paper    && g.p2Move == Move.Rock)     ||
            (g.p1Move == Move.Scissors && g.p2Move == Move.Paper)
        ) {
            winner = g.player1;
        } else {
            winner = g.player2;
        }

        if (winner != address(0)) {
            balances[winner] += 2 * g.bet;
            emit GameResolved(gameId, winner, 2 * g.bet);
        }

        g.state = GameState.Finished;
    }
}
