# 新しいバージョンのWindowsアップデートを適用する

* [Windows 10 のダウンロード](https://www.microsoft.com/ja-jp/software-download/windows10%E3%80%80)

ページ上部にある `Update Assistant` をダウンロードする

<br />

# windowsアップデートができなくなった。

## システムファイルを復元して修復する

* [マイクロソフト コミュニティ](https://answers.microsoft.com/ja-jp/windows/forum/windows_10-update/windows/0f7da171-6236-480a-aba7-7c1cd7c348f4)
* [Windows 10 のアップグレードとインストールに関するエラーのヘルプ](https://support.microsoft.com/ja-jp/windows/windows-10-%E3%81%AE%E3%82%A2%E3%83%83%E3%83%97%E3%82%B0%E3%83%AC%E3%83%BC%E3%83%89%E3%81%A8%E3%82%A4%E3%83%B3%E3%82%B9%E3%83%88%E3%83%BC%E3%83%AB%E3%81%AB%E9%96%A2%E3%81%99%E3%82%8B%E3%82%A8%E3%83%A9%E3%83%BC%E3%81%AE%E3%83%98%E3%83%AB%E3%83%97-ea144c24-513d-a60e-40df-31ff78b3158a)
<br />

システムファイルを復元して修復

```
DISM.exe /Online /Cleanup-image /Restorehealth
```
