name: Build a firmware

on:
  workflow_call:
    inputs:
      keyboard:
        type: string
        required: true   # 例: keyball39
      keymap:
        type: string
        required: true   # 例: default

jobs:
  build:
    name: Build firmware ${{ inputs.keyboard }}:${{ inputs.keymap }}

    runs-on: ubuntu-22.04
    container:
      image: ghcr.io/qmk/qmk_cli:1.2.0
    env:
      PATH: "/usr/bin:/opt/uv/tools/qmk/bin:${PATH}"

    steps:
      # ユーザの keyball リポジトリ
      - name: Checkout keyball repo
        uses: actions/checkout@v4

      - name: Show QMK version
        run: qmk --version

      # QMK 0.22.14 を qmk/ に clone
      - name: Clone QMK 0.22.14
        run: |
          git clone https://github.com/qmk/qmk_firmware.git \
            --depth 1 --recurse-submodules --shallow-submodules \
            -b 0.22.14 qmk
          ls -l qmk

      # キーボードのリンクを QMK へ
      - name: Link keyball directory
        run: |
          mkdir -p qmk/keyboards/keyball
          ln -s $(pwd)/${{ inputs.keyboard }} qmk/keyboards/keyball/${{ inputs.keyboard }}
          echo "==== keyboards/keyball ===="
          ls -R qmk/keyboards/keyball

      # QMK の依存インストール
      - name: Install QMK python dependencies
        run: |
          cd qmk
          /opt/uv/tools/qmk/bin/python3 -m pip install -r requirements.txt

      # ビルド
      - name: Build firmware
        run: |
          cd qmk
          make -j8 SKIP_GIT=yes keyball/${{ inputs.keyboard }}:${{ inputs.keymap }}

      # 生成物表示
      - name: Show artifacts
        run: ls -R qmk/.build

      # アーティファクトを保存
      - name: Upload firmware artifact
        uses: actions/upload-artifact@v4
        with:
          name: ${{ inputs.keyboard }}-${{ inputs.keymap }}-firmware
          path: |
            qmk/.build/*.uf2
            qmk/.build/*.hex
