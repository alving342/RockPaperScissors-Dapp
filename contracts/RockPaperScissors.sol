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
}