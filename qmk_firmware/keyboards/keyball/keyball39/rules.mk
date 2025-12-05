name: Build a firmware

on:
  workflow_call:
    inputs:
      keyboard:
        type: string
        required: true    # 例: keyball39
      keymap:
        type: string
        required: true    # 例: default

jobs:
  build:
    name: Build firmware ${{ inputs.keyboard }}:${{ inputs.keymap }}

    runs-on: ubuntu-22.04
    container:
      image: ghcr.io/qmk/qmk_cli:1.2.0
    env:
      PATH: "/usr/bin:/opt/uv/tools/qmk/bin:${PATH}"

    steps:
      # あなたの keyball リポジトリ
      - name: Checkout keyball repo
        uses: actions/checkout@v4

      - name: Show QMK CLI version
        run: qmk --version

      # 純正 QMK 0.22.14 を qmk/ に clone
      - name: Clone QMK 0.22.14
        run: |
          git clone https://github.com/qmk/qmk_firmware.git \
            --depth 1 --recurse-submodules --shallow-submodules \
            -b 0.22.14 qmk
          ls -l
          ls -l qmk

      # keyball39 を QMK の keyboards/keyball/ にリンク
      - name: Link keyball keyboard directory
        run: |
          cd qmk
          mkdir -p keyboards/keyball
          # ルート直下に keyball39/ がある前提
          ln -s ../keyball39 keyboards/keyball/keyball39
          echo "==== keyboards/keyball ===="
          ls -R keyboards/keyball

      # QMK の Python 依存をインストール
      - name: Install QMK python dependencies
        run: |
          cd qmk
          /opt/uv/tools/qmk/bin/python3 -m pip install -r requirements.txt

      # ビルド
      - name: Build QMK
        run: |
          cd qmk
          make -j8 SKIP_GIT=yes keyball/${{ inputs.keyboard }}:${{ inputs.keymap }}

      # 生成物の確認
      - name: List build artifacts
        run: |
          ls -R qmk/.build

      # uf2 / hex をアップロード
      - name: Upload firmware
        uses: actions/upload-artifact@v4
        with:
          name: ${{ inputs.keyboard }}-${{ inputs.keymap }}-firmware
          path: |
            qmk/.build/*.uf2
            qmk/.build/*.hex
