package org.apache.cordova.camera;

import android.app.Activity;
import android.content.ContentResolver;
import android.content.Intent;
import android.database.Cursor;
import android.net.Uri;
import android.os.Bundle;
import android.provider.MediaStore;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.ImageView;
import android.widget.LinearLayout;
import android.widget.TextView;
import android.widget.Toast;

import java.util.ArrayList;
import java.util.List;

import com.growthengineering.dev1.R;

public class CustomImagePickerActivity extends Activity {
    private List<Uri> selectedImageUris = new ArrayList<>();
    private LinearLayout imageContainer; // Use LinearLayout to hold images

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_custom_image_picker);

        imageContainer = findViewById(R.id.imageContainer); // Reference to the LinearLayout

        // Load images from the gallery or any source
        loadImages();
    }

    private void loadImages() {
        // Get the ContentResolver
        ContentResolver contentResolver = getContentResolver();
        
        // Define the projection (columns to retrieve)
        String[] projection = { MediaStore.Images.Media._ID, MediaStore.Images.Media.DATA };

        // Query the MediaStore for images
        Cursor cursor = contentResolver.query(
                MediaStore.Images.Media.EXTERNAL_CONTENT_URI,
                projection,
                null,
                null,
                MediaStore.Images.Media.DATE_TAKEN + " DESC" // Order by date taken
        );

        if (cursor != null) {
            // Loop through the cursor to get image URIs
            while (cursor.moveToNext()) {
                // Get the image ID
                int idColumn = cursor.getColumnIndexOrThrow(MediaStore.Images.Media._ID);
                long id = cursor.getLong(idColumn);
                Uri imageUri = Uri.withAppendedPath(MediaStore.Images.Media.EXTERNAL_CONTENT_URI, String.valueOf(id));

                // Add the image view for this URI
                addImageView(imageUri);
            }
            cursor.close(); // Close the cursor to free resources
        } 
    }

    private void addImageView(Uri imageUri) {
        // Inflate your custom layout for each image
        View itemView = LayoutInflater.from(this).inflate(R.layout.image_selection_item, null);
        
        ImageView imageView = itemView.findViewById(R.id.imageView);
        TextView selectionIndicator = itemView.findViewById(R.id.selectionIndicator);

        // Load image using your preferred method (e.g., Glide, Picasso)
        // Example: Glide.with(this).load(imageUri).into(imageView);

        // Set an OnClickListener to handle image selection
        itemView.setOnClickListener(v -> {
            if (!selectedImageUris.contains(imageUri)) {
                selectedImageUris.add(imageUri);
                selectionIndicator.setText(String.valueOf(selectedImageUris.size())); // Update selection number
                selectionIndicator.setVisibility(View.VISIBLE); // Show the selection indicator
            } else {
                selectedImageUris.remove(imageUri);
                selectionIndicator.setVisibility(View.GONE); // Hide the selection indicator
            }
        });

        // Add the inflated item view to the LinearLayout
        imageContainer.addView(itemView);
    }

    // When done selecting images, return the result
    private void returnSelectedImages() {
        Intent resultIntent = new Intent();
        resultIntent.putParcelableArrayListExtra("selectedImages", new ArrayList<>(selectedImageUris));
        setResult(Activity.RESULT_OK, resultIntent);
        finish();
    }
}
