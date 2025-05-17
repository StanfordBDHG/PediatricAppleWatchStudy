//
// This source file is part of the PAWS application based on the Stanford Spezi Template Application project
//
// SPDX-FileCopyrightText: 2023 Stanford University
//
// SPDX-License-Identifier: MIT
//

const { getEslintConfig } = require("@stanfordspezi/spezi-web-configurations");

const config = getEslintConfig({ tsconfigRootDir: __dirname });

for (const c of config) {
  c.languageOptions = {
    ...(c.languageOptions || {}),
    ecmaVersion: 2020,
    sourceType: "module",
    globals: {
      ...(c.languageOptions?.globals || {}),
      exports: "readonly",
      process: "readonly",
    },
  };
}

module.exports = config;
