// The module 'vscode' contains the VS Code extensibility API
// Import the module and reference it with the alias vscode in your code below
import * as vscode from "vscode";
import { exec } from "child_process";

// this method is called when your extension is activated
// your extension is activated the very first time the command is executed
export function activate(context: vscode.ExtensionContext) {
  // Use the console to output diagnostic information (console.log) and errors (console.error)
  // This line of code will only be executed once when your extension is activated
  console.log(
    'Congratulations, your extension "peacock-formatter" is now active!'
  );

  // The command has been defined in the package.json file
  // Now provide the implementation of the command with registerCommand
  // The commandId parameter must match the command field in package.json
  let disposable = vscode.commands.registerCommand(
    "peacock-formatter.helloWorld",
    (e) => {
      // vscode.debug.activeDebugConsole.append("wdtf");
      // console.log(e);
      // if (e.fileName.indexOf(".pea") + 4 !== e.fileName.length) return;
      // The code you place here will be executed every time your command is executed
      // Display a message box to the user

      var onSave = vscode.workspace.onDidSaveTextDocument(
        (e: vscode.TextDocument) => {
          // execute some child process on save
          const editor = vscode.window.activeTextEditor;
          if (!editor) return;
          const position = editor?.selection;
          var child = exec("format " + e.fileName);
          child.stdout?.on("data", (data) => {
            vscode.window.showInformationMessage(data);
            editor.selection = position;
          });
          child.stderr?.on("data", (data) => {
            vscode.window.showErrorMessage(data);
          });
        }
      );
      context.subscriptions.push(onSave);
      vscode.window.showInformationMessage(
        "Hello World from peacock-formatter!"
      );
    }
  );

  context.subscriptions.push(disposable);
}

// this method is called when your extension is deactivated
export function deactivate() {}
