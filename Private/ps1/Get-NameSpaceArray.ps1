Function Get-NameSpaceArray{
    $namespaces = kubectl get namespaces -o jsonpath='{.items[*].metadata.name}' | Out-String
    return $namespaces -split " "
}