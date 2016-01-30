# Maple Latte Language Specification

メモ的な感じに

### Sample Script(sample.mls)
```
package maple.sample.hello;

// Java側のクラスを持ってくる(mainメソッド用)
import java.lang;

// スクリプト内プライベートクラスの宣言
bound class HelloWriter
{
	// 返り値の推論(この場合はvoid)
	public run()
	{
		maple.io.writeln("Hello, World.");
	}
}

// ここから下はprivate static class globalの
// 静的初期化子の中身として展開される(privateは「外部パッケージからアクセスできない」を示す)
// globalはスクリプトのキーワードなのでユーザーがクラス宣言することはできない
// valは定数(代入不可)宣言、変数を宣言する場合はvarもしくは型を明示する
// valの代わりにconstも使える(型を明示して定数を宣言するにはconstを使うしかない)
val o = new HelloWriter();
o.run;

// globalクラスの(デフォルト)public staticメンバとして宣言される
void main(String[] args)
{
	// これがないとJavaで実行できない(引数もこれじゃないとダメ)
}
// 以下はエラー
// static void main()

// 実行
// > mlfe -emit=java sample.mls #-emit=javaは省略できる(デフォルト)
// > java maple.sample.hello.global
// もしくは
// > mlfe -emit=llvm sample.mls
// > lli sample.bc
```

## Structure

ソースファイルの構造
* 基本的には宣言(Declarator)を列挙していく
* 先頭にパッケージ宣言(SourcePackageDeclarator, `package <パッケージ名>;`)を書くことができる
  * 効果範囲はソースコード全体
* クラスファイル宣言(SourceClassDeclarator, `class <パッケージ名(省略可)>.<クラス名>;`)を書くと、ファイル全体をクラス内で宣言したものにできる
  * `trait`も同様

## Declarator

### クラス定義
`class <クラス名> extends <親クラス/トレイト名> with <トレイト名> with <トレイト名>...`
* extends節、with節は省略可能

### トレイト定義
`trait <トレイト名> with <トレイト名> with <トレイト名>...`
* with節は省略可能

### 列挙子定義
`enum <列挙子名>`
* Javaのenumと同じであるが、定数以外の宣言を行うことはできない(ので継承も不可)

### テンプレート定義
`template <テンプレート名>(<テンプレート引数>...)`
* コンパイル時に展開される
* ジェネリクスも使用できる(クラス名、トレイト名の後ろに`[<ジェネリクス引数>...]`をつける)
* ジェネリクスは型のみ受け付けるが、テンプレートはコンパイル時に決定できるあらゆるものを受け取ることができる
* テンプレート中に同名のクラス、トレイトを宣言した場合は暗黙的にそのクラス、トレイトとして使用できる
* テンプレート名を省略した場合、次に続く宣言と同名であるものとする
  * 複数宣言が存在した場合はエラーにする

