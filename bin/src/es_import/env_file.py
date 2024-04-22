class EnvFile:
    """
    Parse a .env file

    Parameters
    ----------
        env_file_path : str
            Path of the .env file
    """
    def __init__(self, env_file_path: str) -> None:
        self._env = {}
        with open(env_file_path, "r", encoding='utf-8') as env_file:
            for line in env_file:
                # Skip empty lines and comments
                if not line or line[0] == '#':
                    continue
                env_line = line.split('=', 1)
                self._env[env_line[0]] = env_line[1]

    def get_env(self, key: str) -> str:
        return self._env[key]