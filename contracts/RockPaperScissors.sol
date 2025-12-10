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

    uint256 public nextGameId;
    mapping(uint256 => Game) public games;

    event GameCreated(uint256 indexed gameId, address indexed player1, uint256 bet);
    event GameJoined(uint256 indexed gameId, address indexed player2);
    event MoveCommitted(uint256 indexed gameId, address indexed player);
    event MoveRevealed(uint256 indexed gameId, address indexed player, Move move);
    event GameResolved(uint256 indexed gameId, address winner, uint256 amount);
    event GameCanceled(uint256 indexed gameId);

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
        bytes32 expected;

        if (msg.sender == g.player1) {
            require(!g.p1Revealed, "Already revealed");
            expected = keccak256(abi.encodePacked(move, salt));
            require(expected == g.p1Commit, "Commitment mismatch");
            g.p1Move = move;
            g.p1Revealed = true;
        } else {
            require(!g.p2Revealed, "Already revealed");
            expected = keccak256(abi.encodePacked(move, salt));
            require(expected == g.p2Commit, "Commitment mismatch");
            g.p2Move = move;
            g.p2Revealed = true;
        }

        emit MoveRevealed(gameId, msg.sender, move);

        if (g.p1Revealed && g.p2Revealed) {
            _resolve(gameId);
        }
    }

    function _resolve(uint256 gameId) internal {
        Game storage g = games[gameId];
        require(g.state == GameState.Revealing, "Not revealing");

        address winner;

        if (g.p1Move == g.p2Move) {
            (bool ok1, ) = g.player1.call{value: g.bet}("");
            require(ok1, "P1 refund failed");

            (bool ok2, ) = g.player2.call{value: g.bet}("");
            require(ok2, "P2 refund failed");

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

        if (winner != address(0) && g.p1Move != g.p2Move) {
            uint256 pot = 2 * g.bet;
            (bool ok, ) = winner.call{value: pot}("");
            require(ok, "Payout failed");
            emit GameResolved(gameId, winner, pot);
        }

        g.state = GameState.Finished;
    }
}
