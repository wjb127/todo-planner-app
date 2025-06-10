#!/bin/bash

# App Store 스크린샷 크기 조정 스크립트
# 사용법: ./resize_screenshots.sh input_folder output_folder

INPUT_DIR=${1:-"~/Desktop"}
OUTPUT_DIR=${2:-"./app_store_screenshots"}

# 출력 디렉토리 생성
mkdir -p "$OUTPUT_DIR"

echo "🔧 App Store 스크린샷 크기 조정 시작..."
echo "📁 입력 폴더: $INPUT_DIR"
echo "📁 출력 폴더: $OUTPUT_DIR"

# PNG 파일들을 찾아서 크기 조정
for file in "$INPUT_DIR"/*.png; do
    if [ -f "$file" ]; then
        filename=$(basename "$file")
        echo "📱 처리 중: $filename"
        
        # 1290 × 2796px로 리사이즈 (iPhone 6.7" 세로)
        magick "$file" -resize 1290x2796! "$OUTPUT_DIR/resized_$filename"
        
        echo "✅ 완료: resized_$filename (1290x2796px)"
    fi
done

echo "🎉 모든 스크린샷 크기 조정 완료!"
echo "📂 결과 파일 위치: $OUTPUT_DIR" 