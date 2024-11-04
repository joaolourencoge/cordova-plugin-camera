package org.apache.cordova.camera;

import android.Manifest;
import android.app.Activity;
import android.content.ContentResolver;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.database.Cursor;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.net.Uri;
import android.os.Bundle;
import android.provider.MediaStore;
import android.util.Log;
import android.view.LayoutInflater;
import android.view.View;
import android.widget.Button;
import android.widget.ImageView;
import android.widget.LinearLayout;
import android.widget.TextView;

import androidx.core.app.ActivityCompat;
import androidx.recyclerview.widget.GridLayoutManager;
import androidx.recyclerview.widget.RecyclerView;

import java.util.ArrayList;
import java.util.List;

import com.growthengineering.dev1.R;
import androidx.annotation.NonNull;
import com.growthengineering.dev1.R;
import com.bumptech.glide.Glide;

public class CustomImagePickerActivity extends Activity {
  List<Uri> selectedImageUris = new ArrayList<>();
  private RecyclerView recyclerView;
  private ImageAdapter imageAdapter;
  private List<Uri> imageUris = new ArrayList<>();
  private boolean isLoading = false;
  private LinearLayout imageContainer; // Add this line

  @Override
  protected void onCreate(Bundle savedInstanceState) {
    Log.e("##################### onCreate","##################### onCreate");
    super.onCreate(savedInstanceState);
    setContentView(R.layout.activity_custom_image_picker);
    imageContainer = findViewById(R.id.imageContainer); // Initialize it

    recyclerView = findViewById(R.id.recyclerView);
    imageAdapter = new ImageAdapter(this, imageUris);
    recyclerView.setAdapter(imageAdapter);
    recyclerView.setLayoutManager(new GridLayoutManager(this, 3)); // 3 columns
    recyclerView.setClickable(true);

    loadImages();

    // Set up the Cancel button
    Button btnCancel = findViewById(R.id.btnCancel);
    btnCancel.setOnClickListener(v -> finish()); // Close the activity

    // Set up the Done button
    Button btnDone = findViewById(R.id.btnDone);
    btnDone.setOnClickListener(v -> returnSelectedImages());

    recyclerView.addOnScrollListener(new RecyclerView.OnScrollListener() {
      @Override
      public void onScrolled(@NonNull RecyclerView recyclerView, int dx, int dy) {
        super.onScrolled(recyclerView, dx, dy);
        if (!recyclerView.canScrollVertically(1) && !isLoading) {
          loadMoreImages();
        }
      }
    });
  }

  private void loadImages() {
    Log.e("##################### loadImages","##################### loadImages");

    String[] projection = {MediaStore.Images.Media._ID, MediaStore.Images.Media.DATA};
    ContentResolver contentResolver = getContentResolver();

    Cursor cursor = contentResolver.query(
      MediaStore.Images.Media.EXTERNAL_CONTENT_URI,
      projection,
      null,
      null,
      MediaStore.Images.Media.DATE_TAKEN + " DESC"
    );

    if (cursor != null) {
      Log.e("CustomImagePickerActivity", "Cursor count: " + cursor.getCount());

      while (cursor.moveToNext()) {
        int idColumn = cursor.getColumnIndexOrThrow(MediaStore.Images.Media._ID);
        long id = cursor.getLong(idColumn);
        Uri imageUri = Uri.withAppendedPath(MediaStore.Images.Media.EXTERNAL_CONTENT_URI, String.valueOf(id));
        imageUris.add(imageUri); // Add the image URI to the list
      }
      cursor.close();
    } else {
      Log.e("CustomImagePickerActivity", "Cursor is null");
    }

    imageAdapter.notifyDataSetChanged(); // Notify the adapter of data changes
  }

  private void loadMoreImages() {
    isLoading = true;
    // Load more images logic here
    // After loading, update the adapter and set isLoading to false
    isLoading = false;
  }

  private void addImageView(Uri imageUri) {
    View itemView = LayoutInflater.from(this).inflate(R.layout.image_selection_item, null);
    ImageView imageView = itemView.findViewById(R.id.imageView);
    TextView selectionIndicator = itemView.findViewById(R.id.selectionIndicator);

    // Load image using Glide
    Glide.with(this)
      .load(imageUri)
      .into(imageView);

    imageContainer.addView(itemView);
  }

  // New method to update selection indicators
  void updateSelectionIndicators(int unselectedIndex) {
    Log.e("##################### updateSelectionIndicators", "##################### updateSelectionIndicators");

    // Loop through the selected images
    for (int i = 0; i < selectedImageUris.size(); i++) {
        Uri selectedUri = selectedImageUris.get(i);
        int indexInImageUris = imageUris.indexOf(selectedUri);

        if (indexInImageUris != -1) {
            View child = imageContainer.getChildAt(indexInImageUris);
            if (child != null) { // Check if child is not null
                TextView selectionIndicator = child.findViewById(R.id.selectionIndicator);

                // Check if selectionIndicator is not null
                if (selectionIndicator != null) {
                    // Update selection number
                    selectionIndicator.setText(String.valueOf(i + 1)); // Update selection number
                }
            }
        }
    }

    // Decrease the text for all selected indices greater than the unselected index
    for (int i = unselectedIndex; i < selectedImageUris.size(); i++) {
        Uri selectedUri = selectedImageUris.get(i);
        int indexInImageUris = imageUris.indexOf(selectedUri);

        if (indexInImageUris != -1) {
            View child = imageContainer.getChildAt(indexInImageUris);
            if (child != null) { // Check if child is not null
                TextView selectionIndicator = child.findViewById(R.id.selectionIndicator);

                // Check if selectionIndicator is not null
                if (selectionIndicator != null) {
                    // Decrease the text by 1 for all selected indices greater than the unselected index
                    selectionIndicator.setText(String.valueOf(i)); // Update selection number
                }
            }
        }
    }

    // Hide indicators for unselected images
    for (int i = 0; i < imageContainer.getChildCount(); i++) {
        View child = imageContainer.getChildAt(i);
        TextView selectionIndicator = child.findViewById(R.id.selectionIndicator);
        Uri uri = imageUris.get(i);

        // If the URI is not in the selected list, hide the indicator
        if (!selectedImageUris.contains(uri) && selectionIndicator != null) {
            selectionIndicator.setVisibility(View.GONE); // Hide the selection indicator
        }
    }
  }

  private Bitmap loadBitmapFromUri(Uri uri) {
    try {
      return BitmapFactory.decodeStream(getContentResolver().openInputStream(uri));
    } catch (Exception e) {
      Log.e("CustomImagePickerActivity", "Error loading image from URI: " + uri, e);
      return null;
    }
  }

  // When done selecting images, return the result
  private void returnSelectedImages() {
    Log.d("CustomImagePickerActivity", "Selected URIs: " + selectedImageUris.toString());
    if (selectedImageUris.isEmpty()) {
      Log.e("CustomImagePickerActivity", "No images selected.");
      setResult(Activity.RESULT_CANCELED);
      finish();
      return;
    }

    Intent resultIntent = new Intent();
    ArrayList<Uri> validUris = new ArrayList<>();

    for (Uri uri : selectedImageUris) {
      if (uri != null) {
        validUris.add(uri);
      } else {
        Log.e("CustomImagePickerActivity", "Found null URI in selected images.");
      }
    }

    if (!validUris.isEmpty()) {
      resultIntent.putParcelableArrayListExtra("selectedImages", validUris);
      setResult(Activity.RESULT_OK, resultIntent);
    } else {
      Log.e("CustomImagePickerActivity", "No valid images to return.");
      setResult(Activity.RESULT_CANCELED);
    }

    finish();
  }
}
