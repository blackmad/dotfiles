const fs = require('fs');
const cp = require('child_process');
const util = require('util');
const path = require('path');

const exec = util.promisify(cp.exec);
const writeFile = util.promisify(fs.writeFile);

const ignoreContents = `package-lock.json
yarn.lock
.yarn/releases
`

const prettierConfigVscode = {
    'editor.codeActionsOnSave': {
        'source.fixAll': true,
    },
    '[json]': {
        'editor.defaultFormatter': 'vscode.json-language-features',
    },
    '[javascript]': {
        'editor.defaultFormatter': 'esbenp.prettier-vscode',
    },
    '[typescript]': {
        'editor.defaultFormatter': 'esbenp.prettier-vscode',
    },
};

const eslintRc = {
    parser: '@typescript-eslint/parser',
    parserOptions: {
        ecmaVersion: 2020,
    },
    env: {
        node: true,
    },
    extends: [
        'eslint:recommended',
        'plugin:@typescript-eslint/recommended',
        'plugin:prettier/recommended',
        'eslint-plugin-unused-imports'
    ],
    rules: {
      complexity: [ 'warn', 10 ],
      'prefer-const': 'error',
      '@typescript-eslint/no-explicit-any': 'off',
      '@typescript-eslint/no-var-requires': 'off',
      '@typescript-eslint/no-unused-vars': 'error',
      '@typescript-eslint/no-non-null-assertion': 'off',
      '@typescript-eslint/explicit-module-boundary-types': 'off',
      'sort-imports': ['error'],
      "no-unused-vars": "off",
      "@typescript-eslint/no-unused-vars": "off",
      "unused-imports/no-unused-imports": "error",
      "unused-imports/no-unused-vars": [
          "warn",
          { "vars": "all", "varsIgnorePattern": "^_", "args": "after-used", "argsIgnorePattern": "^_" }
      ]
    //   'padding-line-between-statements': [
    //     'error',
    //     { blankLine: 'always', prev: '*', next: 'if' },
    //     { blankLine: 'always', prev: '*', next: 'block-like' },
    //     { blankLine: 'always', prev: '*', next: 'block' }
    //   ]
    },
};

const prettierRc = {
    tabWidth: 2,
    singleQuote: true,
    printWidth: 80,
    trailingComma: 'all',
};

const packages = [
    '@typescript-eslint/eslint-plugin',
    '@typescript-eslint/parser',
    'eslint-config-prettier',
    'eslint-plugin-prettier',
    'eslint',
    'prettier',
    'eslint-plugin-unused-imports',
    'sort-imports'
];

const execCommand = async (command) => {
    return new Promise((resolve, reject) => {
      const [cmd, ...args] = command.split(' ');
      const childProcess = cp.spawn(cmd, args);
      childProcess.stdout.on('data', (data) => {
        process.stdout.write(data.toString());
      });
      childProcess.stderr.on('data', (data) => {
        process.stderr.write(data.toString());
      });
      childProcess.on('error', (error) => {
        reject(error);
      });
      childProcess.on('exit', (code) => {
        if (code === 0) {
          resolve();
        } else {
          reject(new Error(`Command exited with code ${code}.`));
        }
      });
    });
  };

(async () => {
    const vscodeDirPath = path.join(__dirname, '.vscode');

    try {
        fs.statSync(vscodeDirPath).isDirectory();
    } catch (error) {
        fs.mkdirSync(vscodeDirPath);
    }

    const workspacePath = path.join(
        __dirname,

        '.vscode',
        'settings.json',
    );
    let workspaceSettings = {};

    try {
        fs.statSync(workspacePath).isFile();
    } catch (error) {}

    workspaceSettings = {
        ...workspaceSettings,
        ...prettierConfigVscode,
    };

    const installCommand = `yarn add -D ${packages.join(' ')}`

    await Promise.all([
        writeFile(
            '.ignore',
            ignoreContents,
        ).then(() => console.log('writing new .ignore settings')),
        writeFile(
            workspacePath,
            JSON.stringify(workspaceSettings, null, 2),
        ).then(() => console.log('writing new .vscode/settings.json')),
        writeFile(
            '.eslintrc.json',
            JSON.stringify(eslintRc, null, 2),
        ).then(() => console.log('writing new .eslintrc.json')),
        writeFile(
            '.prettierrc.json',
            JSON.stringify(prettierRc, null, 2),
        ).then(() => { console.log('writing new .prettierrc.json'); console.log(`installing packages with\n\t${installCommand}`); }),
        execCommand(installCommand)
            .catch(console.log),
    ]);
    
    console.log('Finished installing all dependencies and configuring files.\nYou may need to restart vscode for the eslint / prettier settings to take effect.\nI believe you also need the prettier and eslint extensions installed in vscode.');
})();
