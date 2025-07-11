#!/bin/bash
set -e

APP_NAME="icon_logo"
VERSION="$1"
BUILD_DIR="build"
FORMULA_FILE="${APP_NAME}.rb"
REPO_URL="https://github.com/zk3151463/icon_logo"
RELEASE_URL="${REPO_URL}/archive/refs/tags/v${VERSION}.tar.gz"

TAP_REPO="https://github.com/zk3151463/homebrew-icon_logo.git"
TAP_DIR="homebrew-icon_logo"
TAP_BRANCH="main"

PLATFORMS=(
  "darwin amd64"
  "darwin arm64"
  "linux amd64"
)

if [ -z "$VERSION" ]; then
  echo "❌ 用法: $0 <version>，例如: ./publish.sh 1.0.0"
  exit 1
fi

# === 1. 自动创建 git tag（如果不存在） ===
echo "🏷️ 检查/创建 git tag v$VERSION..."
if ! git rev-parse "v$VERSION" >/dev/null 2>&1; then
  git tag "v$VERSION"
  git push origin "v$VERSION"
else
  echo "✅ Git tag v$VERSION 已存在"
fi

# === 2. 构建多平台包 ===
echo "🧼 清理旧构建..."
rm -rf "$BUILD_DIR" *.tar.gz "$FORMULA_FILE"
mkdir -p "$BUILD_DIR"

echo "🛠️ 构建多个平台版本..."
for platform in "${PLATFORMS[@]}"; do
  os=$(echo $platform | awk '{print $1}')
  arch=$(echo $platform | awk '{print $2}')
  output_dir="${BUILD_DIR}/${APP_NAME}-${VERSION}-${os}-${arch}"
  output_file="${output_dir}/${APP_NAME}"

  mkdir -p "$output_dir"
  echo "🚧 构建: $os/$arch -> $output_file"
  GOOS=$os GOARCH=$arch go build -o "$output_file" .
  tar_name="${APP_NAME}-${VERSION}-${os}-${arch}.tar.gz"
  tar -czf "$tar_name" -C "$BUILD_DIR" "$(basename $output_dir)"
done

# === 3. 计算 Homebrew 用的 sha256 ===
HOMEBREW_TAR="${APP_NAME}-${VERSION}-darwin-amd64.tar.gz"
echo "🔐 计算 darwin/amd64 sha256..."
SHA256=$(shasum -a 256 "$HOMEBREW_TAR" | awk '{print $1}')
echo "SHA256: $SHA256"

# === 4. 生成 Homebrew Formula 文件 ===
echo "🧾 生成 Formula 文件: $FORMULA_FILE"
cat > "$FORMULA_FILE" <<EOF
class IconLogo < Formula
  desc "图标生成工具"
  homepage "${REPO_URL}"
  url "${RELEASE_URL}"
  sha256 "${SHA256}"
  license "MIT"

  depends_on "go" => :build

  def install
    system "go", "build", *std_go_args
  end

  test do
    assert_match "Usage", shell_output("\#{bin}/$APP_NAME --help")
  end
end
EOF

# === 5. 上传 GitHub Release ===
echo "🚀 上传构建文件到 GitHub Release..."
if gh release view v${VERSION} > /dev/null 2>&1; then
  echo "🔁 Release v${VERSION} exists. Uploading assets..."
  for f in ${APP_NAME}-${VERSION}-*.tar.gz; do
    gh release upload v${VERSION} "$f" --clobber
  done
else
  echo "🆕 创建新 Release v${VERSION} 并上传构建文件"
  gh release create v${VERSION} ${APP_NAME}-${VERSION}-*.tar.gz \
    -t "v${VERSION}" -n "Release ${APP_NAME} version ${VERSION}"
fi

# === 6. 提交 Formula 到 Tap 仓库 ===
echo "📤 推送 Formula 到 Homebrew Tap..."
if [ ! -d "$TAP_DIR" ]; then
  git clone "$TAP_REPO" "$TAP_DIR"
fi

cd "$TAP_DIR"
git checkout "$TAP_BRANCH"
git pull origin "$TAP_BRANCH"
cp ../$FORMULA_FILE ./
git add $FORMULA_FILE
git commit -m "${APP_NAME}: update formula to version ${VERSION}" || echo "⚠️ Nothing to commit"
git push origin "$TAP_BRANCH"
cd ..

echo ""
echo "✅ 所有流程完成！你现在可以运行以下命令进行安装："
echo "-------------------------------------------------"
echo "brew tap zk3151463/icon_logo"
echo "brew install ${APP_NAME}"
echo "-------------------------------------------------"
echo "🎉 发布 v${VERSION} 成功！"
