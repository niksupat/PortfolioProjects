-- Viewing the data

SELECT *
FROM NashvilleHousing

-- 1) Standardising the date format
-- Viewing non-converted data with conversion preview
SELECT SaleDate, CONVERT(date, SaleDate)
FROM NashvilleHousing

-- Adding new column
ALTER TABLE NashvilleHousing
ADD SaleDateConverted DATE

-- Adding converted sale date into new column
UPDATE NashvilleHousing
SET SaleDateConverted = CONVERT(date, SaleDate)

-- 2) Populate Property Address data; here we see that for NULL values of Property Address, we can populate the field with the 
-- property address of another house with the same ParcelID */

SELECT *, PropertyAddress
FROM NashvilleHousing
-- WHERE PropertyAddress IS NULL
ORDER BY ParcelID

-- Need to do self-join here; where a.PropertyAddress is null, then we want to populate with b.PropertyAddress
SELECT a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM NashvilleHousing a
    JOIN NashvilleHousing b
    ON a.ParcelID = b.ParcelID AND a.UniqueID <> b.UniqueID
WHERE a.PropertyAddress IS NULL

-- Update the table with the changed data
UPDATE a
SET PropertyAddress = ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM NashvilleHousing a
    JOIN NashvilleHousing b
    ON a.ParcelID = b.ParcelID AND a.UniqueID <> b.UniqueID
WHERE a.PropertyAddress IS NULL

-- Double check to see there are no more NULL values in PropertyAddress field
SELECT *
FROM NashvilleHousing
WHERE PropertyAddress IS NULL

-- 3) Breaking out PropertyAddress into individual columns for easier processing (Address, City, State)
SELECT PropertyAddress
FROM NashvilleHousing
-- WHERE PropertyAddress IS NULL
-- ORDER BY ParcelID

-- Preview of altered data
SELECT
    SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) - 1) AS ADDRESS,
    SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) +2, LEN(PropertyAddress)) AS ADDRESS2
FROM NashvilleHousing;

-- Create 2 new columns and add the altered data in
-- Adding new column
ALTER TABLE NashvilleHousing
ADD PropertySplitAddress NVARCHAR(255)

-- Adding new property address into new column
UPDATE NashvilleHousing
SET PropertySplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) - 1)

-- Adding new column
ALTER TABLE NashvilleHousing
ADD PropertySplitCity NVARCHAR(255)

-- Adding converted sale date into new column
UPDATE NashvilleHousing
SET PropertySplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) +2, LEN(PropertyAddress))

-- 4) Breaking out OwnerAddress into individual columns for easier processing (Address, City, State)
SELECT OwnerAddress
FROM NashvilleHousing

SELECT
    PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3),
    PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2),
    PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1)
FROM NashvilleHousing

-- Create 3 new columns and add the altered data in
-- Adding new column
ALTER TABLE NashvilleHousing
ADD OwnerSplitAddress NVARCHAR(255)

-- Adding new property address into new column
UPDATE NashvilleHousing
SET OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3)

-- Adding new column
ALTER TABLE NashvilleHousing
ADD OwnerSplitCity NVARCHAR(255)

-- Adding new property address into new column
UPDATE NashvilleHousing
SET OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2)

-- Adding new column
ALTER TABLE NashvilleHousing
ADD OwnerSplitState NVARCHAR(255)

-- Adding new property address into new column
UPDATE NashvilleHousing
SET OwnerSplitState = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1)

-- 5) Change Y and N to Yes and No in 'Sold as Vacant' field
SELECT Distinct(SoldAsVacant), COUNT(SoldAsVacant)
FROM NashvilleHousing
GROUP BY SoldAsVacant
ORDER BY SoldAsVacant

-- Previewing changes to data
SELECT
    SoldAsVacant,
    CASE 
        WHEN SoldAsVacant = 'Y' THEN 'Yes'
        WHEN SoldAsVacant = 'N' THEN 'No'
        ELSE SoldAsVacant
    END
FROM NashvilleHousing

-- Update and alter data within the table
UPDATE NashvilleHousing
SET SoldAsVacant =
    CASE 
        WHEN SoldAsVacant = 'Y' THEN 'Yes'
        WHEN SoldAsVacant = 'N' THEN 'No'
        ELSE SoldAsVacant
    END

-- 6) Remove duplicates using a CTE
WITH
    RowNumCTE
    AS
    (
        SELECT *,
            ROW_NUMBER() OVER (
        PARTITION BY ParcelID, PropertyAddress, SalePrice, SaleDate, LegalReference
        ORDER BY UniqueID) AS RowNumber
        FROM NashvilleHousing
    )
SELECT *
FROM RowNumCTE
WHERE RowNumber > 1

-- 7) Delete unused columns

SELECT *
FROM NashvilleHousing

ALTER TABLE NashvilleHousing
DROP COLUMN OwnerAddress, TaxDistrict, PropertyAddress, SaleDate