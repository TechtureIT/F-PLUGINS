package akki7272.filepicker3;

import android.app.Activity;
import android.content.Intent;
import android.database.Cursor;
import android.net.Uri;
import android.provider.OpenableColumns;

import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;

import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.PluginRegistry;
import io.flutter.plugin.common.PluginRegistry.Registrar;

/**
 * Filepicker3Plugin
 */
public class Filepicker3Plugin implements MethodCallHandler, PluginRegistry.ActivityResultListener {
    private static final int READ_REQUEST_CODE = 101;
    private final Registrar registrar;

    private Result pendingResult;

    /**
   * Plugin registration.
   */
  public static void registerWith(Registrar registrar) {
    final MethodChannel channel = new MethodChannel(registrar.messenger(), "filepicker3");
      final Filepicker3Plugin instance = new Filepicker3Plugin(registrar);
      registrar.addActivityResultListener(instance);
    channel.setMethodCallHandler(instance);
  }

    private Filepicker3Plugin(Registrar registrar) {
        this.registrar = registrar;
    }

    @Override
  public void onMethodCall(MethodCall call, Result result) {

//        if (pendingResult != null) {
//            result.error("ALREADY_ACTIVE", "File dialog is already active", null);
//            return;
//        }

      Activity activity = registrar.activity();
      if (activity == null) {
          result.error("NO_ACTIVITY", "import_file plugin requires a foreground activity.", null);
          return;
      }

      pendingResult = result;
    if (call.method.equals("selectFile")) {


        Intent importIntent = new Intent();
        importIntent.setAction(Intent.ACTION_GET_CONTENT);
        importIntent.addCategory(Intent.CATEGORY_OPENABLE);
        importIntent.setType("*/*");
        activity.startActivityForResult(importIntent, READ_REQUEST_CODE);

    }else if (call.method.equals("getPlatformVersion")) {


      result.success("Android " + android.os.Build.VERSION.RELEASE);



    } else {
      result.notImplemented();
    }
  }

    @Override
    public boolean onActivityResult(int requestCode, int resultCode, Intent intent) {
        if (requestCode == READ_REQUEST_CODE) {
            if (resultCode == Activity.RESULT_OK) {
                Uri uri = intent.getData();
                String fileName = null;
                if (uri.getScheme().equals("content")) {
                    Cursor cursor = registrar.activity().getContentResolver().query(uri, null, null, null, null);
                    try {
                        if (cursor != null && cursor.moveToFirst()) {
                            fileName = cursor.getString(cursor.getColumnIndex(OpenableColumns.DISPLAY_NAME));
                        }
                    } finally {
                        cursor.close();
                    }
                }
                if (fileName == null) {
                    fileName = uri.getPath();
                    int cut = fileName.lastIndexOf('/');
                    if (cut != -1) {
                        fileName = fileName.substring(cut + 1);
                    }
                }
                try {
                    File file = File.createTempFile(fileName, "", registrar.context().getCacheDir());
                    InputStream input = registrar.activity().getContentResolver().openInputStream(uri);
                    try {
                        OutputStream output = new FileOutputStream(file);
                        try {
                            byte[] buffer = new byte[4 * 1024];
                            int read;
                            while ((read = input.read(buffer)) != -1) {
                                output.write(buffer, 0, read);
                            }
                            output.flush();
                        } finally {
                            output.close();
                        }
                    } finally {
                        input.close();
                    }
                    pendingResult.success(file.getAbsolutePath().toString());
                } catch (IOException e){
                    pendingResult.error("IMPORT_ERROR", "Error importing file", null);
                }
            } else if (resultCode != Activity.RESULT_CANCELED) {
                pendingResult.error("IMPORT_ERROR", "Error importing file", null);
            }
            pendingResult = null;
            return true;
        }
        return false;
    }
}
